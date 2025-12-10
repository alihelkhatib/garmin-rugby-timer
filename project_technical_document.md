# Project Technical Document

## Overview
- Repository: `rugby-timer`
- Language: Monkey C (Garmin Connect IQ)
- Target platforms: Garmin Fenix 6 family (260x260), Handle differences for `6S/6X`
- Purpose: Rugby match timing, scorekeeping, discipline tracking, GPS recording with session persistence.

## Architecture
- Entry point: `source/RugbyTimerApp.mc` registers viewer/delegate.
- View: `source/RugbyTimerView.mc` renders scoreboard, timers, cards, persists state, handles gameplay logic and settings.
- Delegate/menus: `RugbyTimerDelegate.mc` routes hardware actions and menu interactions.
- Settings/UI resources under `resources/menus`, `resources/strings`, `resources/layouts`.
- Manifest defines Fenix 6 products and permissions (Fit, Positioning, Sensor, SensorLogging).

## Key Behaviors
- Game states: playing, paused, conversion, penalty, halftime, ended.
- Score dialog: team → score type, limited during conversion timer (made/miss).
- Card tracking: multiple yellow timers per team, red timers (permanent for 7s). Display stacks with numbering.
- Persistence: periodic state saves plus final summary stored at game end (`lastGameSummary`).
- Layout and rendering: positions for the scoreboard, main timers, and card timers adjust dynamically so the game/countdown clocks stay visible even when several card timers stack below, with the cards spaced and colored clearly.
- Haptic alert at 30 seconds remaining when countdown active (if supported).
- GPS/tracking hook collects position updates, trimmed to keep size bounded.

## Settings and Resources
- Settings menu allows toggling conversion/penalty timers, adjusting durations, lock-on-start, dim theme.
- Layouts and strings contain simple label-based content; additional menus defined in `resources/menus/menu.xml`.

## Build
```
monkeyc -f monkey.jungle -o bin\rugbytimer.prg -y developer_key -d fenix6
```
Requires Connect IQ SDK 8.x (path configured via `monkeybrains.jar`).

## Development Notes
- Monitor `log.md` for session recap before continuing.
- Keep `source/` contents updated; `monkey.jungle` points there.
- Use storage keys consistently (e.g., `gameStateData`, `lastGameSummary`).

## Next Steps (Example)
1. Add haptics for conversion completion.
2. Introduce stats view with GPS distance/speed.
3. Improve layout for small devices if needed.
