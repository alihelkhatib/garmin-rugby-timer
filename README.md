# Rugby Timer for Garmin Watches

This Connect IQ watch app supports the modern Fenix 6/7/8, Epix, Forerunner (255/265/945/955/965), Venu, and Instinct families: it tracks scores, halves, countdowns, yellow/red cards, conversions/penalties, and a GPS `SPORT_RUGBY` recording while adapting the layout so the core timers stay visible even when multiple card timers stack below.

## Highlights
- Game clock and countdown split so referees see both the live game time and the active countdown/bonus window.
- Layout math keeps the countdown, state text, and card stacks from stepping on each other no matter how many timers are visible, letting the main clocks stay readable on every supported screen size.
- Dialog-driven scoring/card capture with conversion/penalty shortcuts, event log export, GPS activity recording, and auto-cleared timers on reset/end.
- Event Log accessible from the BACK/LAP (Exit) dialog so referees can save a time-stamped list of every try, conversion, penalty, drop goal, and card.
- Yellow cards store their `Y#` labels and persist even when additional cards are added; totals per team are kept for final summaries.
- Includes a 40×40 launcher icon and activity persistence/storage keys so you can resume games or hand data off later.

## Requirements
- [Garmin Connect IQ SDK 8.3.x](https://developer.garmin.com/connect-iq/) (already referenced via `monkeybrains.jar` in the project).
- This project targets the Fenix 6/7/8, Epix, Forerunner (255/265/945/955/965), Venu, and Instinct watch lines; adjust the `<iq:product>` entries in `manifest.xml` if you need to ship to a narrower set of devices.
- `monkeyc`, `monkeydo`, and the device simulators installed.
- Windows/macOS terminal with access to the `monkeyc` toolchain. The repo currently targets fenix6/fenix6pro/fenix6s/fenix6spro/fenix6xpro.

## Build & Install
```bash
monkeyc -f monkey.jungle -o bin/rugbytimer.prg -y developer_key -d fenix6
```

Then load `bin/rugbytimer.prg` in the simulator or sideload to a compatible watch (use Garmin Express or WebUpdater to drag-and-drop the `.prg`). The same `.prg` can be copied to other Fenix 6 variants by changing the `-d` flag and rebuilding.

## Usage Notes
- **Start/pause**: Press `SELECT` to start/pause/resume even during conversions, penalties, or kickoff replays.
- **Score/discipline**: Use the `UP`/`DOWN` buttons (or menu entries) to log scores/cards and conversions. Back/LAP opens the Exit dialog, which now exposes the Event Log.
- **Event log**: Save the timeline to `Storage` under `eventLogExport`, then retrieve it later for post-game reporting.
- **Activity recording**: GPS tracking begins when the match starts and logs as `Activity.SPORT_RUGBY`; ending the game calls `stopRecording()` to save the session.

## Testing & Logging
- Manual: Launch the Fenix simulator, add scores/cards, and exercise the Event Log/Exit flow. Confirm countdown/court timers adjust with card stacks and the log exports text.
- Log updates in `log.md` summarize every major change so future maintainers know the current behavior and test history.

## Documentation
- `project_technical_document.md` describes architecture, timer math, storage keys, and the Event Log/Activity behavior.
- `AGENTS.md` explains contributor expectations, coding style, and the per-change commit rule.

## Release
- The `bin/` directory already contains a built `rugbytimer.prg`; regenerate it whenever you change `source/`.
- Document manual tests in `log.md` and update the Event Log entry if you adjust the release flow (e.g., new menu shortcuts or timer rules).
