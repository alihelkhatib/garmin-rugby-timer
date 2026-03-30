# Project Technical Document

## Overview
- Repository: `rugby-timer`
- Language: Monkey C (Garmin Connect IQ)
- Target platforms: Garmin Fenix 6/7/8 families, Epix (Pro/Sapphire), Forerunner 255/255S/255S+, 745/945/955/965 series, Venu 2/2+, and Instinct 2—any device that can render the current layout without additional scaling.
- Purpose: Rugby match timing, scoring, discipline tracking, GPS `SPORT_RUGBY` recording, overlay dialogs for conversions/penalties, event-logging, and data persistence/export.

## Architecture
- `RugbyTimerApp.mc`: App entry point and provider for the main view/delegate pair.
- `RugbyTimerDelegate.mc`: Handles button presses and menu entries, including idle half-length adjustments on UP/DOWN, BACK/LAP menu items (`Event Log`, `Save Game`, `Reset Game`), and delegating to the overlay/timing helpers.
- `RugbyTimerView.mc`: Central orchestrator that wires the helper modules, triggers UI updates, and keeps gameplay state (scores, conversions, card timers, GPS tracking, persisted summaries) in sync without showing a startup game-type prompt.
- `RugbyTimerRenderer.mc`: Computes layout offsets for the scoreboard (`baseTimerY`, `candidateTimerY`, half/state text, card stack positions) and draws the card timers, countdown/game clocks, and overlay background so the view can remain lean.
- `RugbyTimerTiming.mc`: Runs the shared `onUpdate` loop, keeps the `countdownTimer` and `gameTimer` decoupled, emits event-specific haptics (half warning, start/pause/resume, lock, conversion/penalty warnings and expiry, yellow warnings and expiry), and manages conversion/penalty timer synchronization.
- `RugbyTimerCards.mc`: Tracks yellow/red timer dictionaries per team, enforces “only two visible timers per side” while keeping hidden ones ticking, preserves `Y#`/`R#` labels across replacements, and exposes pause/resume helpers.
- `RugbyTimerOverlay.mc`: Renders the conversion/penalty overlay screen with prompts (UP = success, DOWN = miss) plus countdown text, confirmation message, and ensures the main countdown label stays white while the special timer matches the overlay color.
- `RugbyTimerPersistence.mc`: Saves/restores game state (`gameStateData`, `eventLog`, `lastGameSummary`), serializes durable remaining-time snapshots for cards/red timers, reopens live saved matches as paused resumable state, clears cards on reset/finish, records totals per color/team, and wires the “Save log” action to Storage.
- `RugbyTimerEventLog.mc`: Formats timestamped entries (`HH:MM – Home Try`) into `lastEvents` and exposes the log view so referees can export it via the Exit dialog.
- `RugbySettings.mc`: Owns the idle-only setup menus for built-in match profiles (`7s`, `10s`, `15s`, `U19`, `Custom`), the editable format family/timer rows, theme, and reset behavior; profile/family/half length are locked once a match starts.
- `RugbyMatchProfiles.mc`: Defines the preset rule packs, migrates older `rugby7s`/per-type duration storage into the new `matchProfileId` + `Custom` profile model, and preserves user-edited custom values separately from the built-in presets.

## Layout Math Notes
- `baseTimerY` defines the preferred vertical anchor for the big clocks (game timer at the top, countdown below when overlay inactive). `candidateTimerY` is a computed Y coordinate that moves up/down to avoid overlapping with the card stack; the renderer clamps the final `countdownY` between `countdownMin` and `countdownLimit`.
- `stateY` and `hintY` define where the “Half #” text, tries indicator, and hint text reside. The renderer shifts these downward whenever the countdown climbs into the card stack zone so the timers and card displays never overlap.
- Card timers start at `cardsY` and push down incrementally; the renderer adds vertical padding between each card and between colors so stacked timers remain legible even when extras remain hidden (tracked internally).
- The overlay keeps the main countdown visible near the top and the special timer centered, preventing the red conversion text from touching the scoreboard.
- A small play/pause icon anchors near the top-left (`iconY = height * 0.04` with an ~8% horizontal inset), reflecting the current game state, and a lock icon sits near the top-right above the scores when the UI is locked.

## Key Behaviors
- Idle setup: the app now opens directly on the main timer screen, the referee can adjust half length immediately with UP/DOWN, and Settings exposes a `Profile` row for quick switching between Rugby 7s, 10s, 15s, U19, and the saved `Custom` preset.
- Resume behavior: when the app is reopened during a live match, the saved state returns as a paused snapshot with the prior live state kept in `pausedState`, so the referee can resume safely instead of inheriting stale timer baselines.
- Game states: countdown sharing (minutes/seconds), conversion/penalty overlays, halftime, and finished.
- Conversion flow: pressing `UP`/`DOWN` during the overlay records success/miss, applies score updates, and closes the overlay while keeping the main countdown and card timers running.
- Conversion and penalty timers stay synchronized with the main countdown; they never pause unless the user pauses the countdown (Select), but the game timer continues running regardless of countdown state. Kickoff no longer opens a timed overlay, so play resumes directly after conversion handling.
- Countdown rendering now uses one shared display-rounding helper for the main countdown, special overlay, and inline conversion/penalty labels so the special timers do not appear to trail the main clock by a second on different screens.
- Card stacks: Up to two visible timers per team. Additional timers keep counting without visibility until a slot frees up. Yellow timers vibrate once at <=10 seconds and again when one or more cards expire during the same update cycle. All timers reset on “Reset Game” or game completion.
- Haptics: the watch now uses distinct patterns for match start, pause, resume, half-time, full-time, lock toggle, conversion start/10-second warning/expiry, penalty start/10-second warning/expiry, and yellow-card warning/expiry so referees do not need to stare at the screen continuously.
- Settings: `Profile`, `Format Family`, and `Half Timer` are idle-only, `Lock on Start` applies at the start of each half, and manual timer edits promote the active profile to the persistent `Custom` preset automatically.
- Event log: Every scoring or card event logs a human-readable string with `System.getTimer()` timestamps and appends to `lastEvents`. The BACK/LAP dialog exposes the Event Log view and a “Save log” action that persists the list to Storage for post-match sharing.
- GPS tracking: When the match starts, `Activity.SPORT_RUGBY` recording begins automatically (distance/speed overlays are queued for future work); stopping the game halts GPS logging and writes the record so Connect IQ syncs the rugby session.

## Persistence & Release Notes
- `resources/drawables/` now includes a 40×40 launcher icon referenced in `resources/drawables/drawables.xml` and the manifest; replace it only with same-size assets to avoid scaling warnings.
- Every change touching gameplay logic must be committed separately, and the release flow includes documentation updates in `log.md` + `project_technical_document.md`.
- `bin/rugbytimer.prg` should be rebuilt via `monkeyc` after every source change, and the path to `monkeyc.exe` (shown in `AGENTS.md`) must be captured in `log.md`.
- Release automation runs through `.github/workflows/build_and_publish.yml`, which downloads the same SDK, invokes `monkeybrains.jar`, creates a GitHub release, and uploads the PRG to the Connect IQ Store whenever `CONNECTIQ_STORE_TOKEN` is set.
