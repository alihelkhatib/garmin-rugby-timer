# Copilot Agent Context

<!-- AUTO-GENERATED SECTION — DO NOT EDIT BETWEEN MARKERS -->
<!-- BEGIN:AUTO -->

## Project: Garmin Rugby Timer

- **Language**: Monkey C (Garmin Connect IQ)
- **SDK**: `connectiq-sdk-win-8.3.0-2025-09-22-5813687a0`
- **Build artifact**: `bin/rugbytimer.prg`
- **Build target (CI)**: `fenix6_sim`
- **Build command**: `java -jar <SDK_PATH>/bin/monkeybrains.jar -o bin/rugbytimer.prg -f monkey.jungle -y developer_key -d fenix6_sim -w`

## Key Source Modules

| File | Responsibility |
|---|---|
| `RugbyGameModel.mc` | All game state; single source of truth |
| `RugbyTimerRenderer.mc` | All layout math and drawing (no state mutations) |
| `RugbyTimerTiming.mc` | Countdown/game timer logic and haptics |
| `RugbyTimerCards.mc` | Yellow/red card timer dictionaries |
| `RugbyTimerOverlay.mc` | Overlay screen rendering and interaction |
| `RugbyTimerPersistence.mc` | Save/restore and export |
| `RugbyTimerEventLog.mc` | Event formatting and log view |
| `RugbyTimerView.mc` | Game state orchestration |
| `RugbyTimerDelegate.mc` | Button/menu input handling |
| `RugbySettings.mc` | Settings menu and pickers |

## Storage Keys (Toybox.Application.Storage)

| Key | Type | Description |
|---|---|---|
| `rugby7s` | Boolean | Last selected game type (true = 7s, false = 15s) |
| `halfDuration7s` | Number (s) | Saved half duration for 7s games (new — feature 002) |
| `halfDuration15s` | Number (s) | Saved half duration for 15s games (new — feature 002) |
| `countdownTimer` | Number (s) | Legacy key — read-only fallback; no longer written by new code |
| `conversionTime7s` | Number (s) | 7s conversion timer duration |
| `conversionTime15s` | Number (s) | 15s conversion timer duration |
| `penaltyKickTime` | Number (s) | Penalty kick timer duration |
| `useConversionTimer` | Boolean | Conversion timer enabled |
| `usePenaltyTimer` | Boolean | Penalty timer enabled |
| `lockOnStart` | Boolean | Lock screen on game start |
| `dimMode` | Boolean | Dim theme toggle |

## UI Patterns

- Free-form minute picker: `MinutesPicker(initialMinutes)` — two-column `WatchUi.Picker` (tens × units, 0–9 each); hosted in `RugbySettings.mc`
- Picker used for game-start duration: `WatchUi.pushView(new MinutesPicker(defaultMinutes), new NewGameTimerPickerDelegate(...))` in `RugbyTimerDelegate.mc`
- Menu items disabled during match: pass `{:enabled => false}` in `WatchUi.MenuItem` constructor

## Active Features (branch 002-custom-half-timer)

- Per-game-type half duration persistence (`halfDuration7s` / `halfDuration15s`)
- Settings "Half Timer" disabled while match in progress
- New-game picker pre-fills from per-type saved value
- `setGameType()` loads per-type duration instead of overwriting with hardcoded default
- `setHalfDuration()` writes to per-type key

<!-- END:AUTO -->

<!-- MANUAL ADDITIONS -->
<!-- Add project-specific notes below. This section is preserved between auto-updates. -->
