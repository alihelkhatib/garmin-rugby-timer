## [2026-03-30] Restore Fenix short-press up/menu conversion make path

- Wired the conversion overlay's `+2` action back onto the `onPreviousPage` / `KEY_UP` behavior path in addition to the `onMenu` / `KEY_MENU` path, which matches the Fenix 6 middle-left `UP/MENU` button short press.
- `MISS` remains on the bottom-left `DOWN` path, and the overlay action guard still de-duplicates follow-up events if both raw-key and behavior callbacks fire for the same physical press.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (existing container-analysis warnings and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Restrict conversion make to Fenix menu button path

- Removed the raw `KEY_UP` shortcut from the conversion overlay so `+2` is only awarded through the actual `UP/MENU` button path (`onMenu` / `KEY_MENU`) on Fenix-class watches.
- The upper-left button is now consumed during the conversion overlay without scoring, which prevents accidental made conversions from the wrong physical button on Fenix 6 hardware.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (existing container-analysis warnings and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Separate conversion timer from lower prompt zone

- Moved the large red conversion timer into a higher center-band anchor and pushed the lower `MISS` prompt farther down the left side, so the lower prompt no longer competes with the large countdown digits.
- Kept the simplified overlay style from the prior pass: no `COUNTDOWN` title and minimal `+2` / `MISS` prompts only.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (existing container-analysis warnings and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Simplify conversion overlay prompt layout

- Removed the `COUNTDOWN` title from the conversion overlay, leaving only the live main countdown value at the top.
- Simplified the left-side conversion prompts to `+2` and `MISS` only, and widened the minimum bezel-aware left inset so those prompt labels sit farther inside the visible screen area on round watches.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (existing container-analysis warnings and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Decouple try scoring from overlay view-stack transitions

- Removed the direct `rugbyView.showSpecialTimerScreen()` handoff from the nested `ScoreTypeDelegate` try callback. The main view now auto-opens the conversion overlay whenever the model enters `STATE_CONVERSION`, which avoids the previous `popView/popView/show overlay` sequence in the `MENU -> Score -> Try` path.
- Wrapped the score/menu delegates and `persistState()` in defensive handlers so a storage or menu-transition failure during try registration no longer terminates the app.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (existing container-analysis warnings and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Guard try-triggered conversion overlay rendering

- Hardened `RugbyTimerOverlay.mc` so the full special-overlay draw path runs behind a defensive fallback. If a device-specific conversion prompt render fails right after a try opens the overlay, the app now drops to a simplified conversion screen instead of crashing.
- Also removed the prompt-render exception message formatting that depended on exception object methods, keeping the recovery path safe even on devices with slightly different runtime behavior.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (existing container-analysis warnings and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Device-aware overlay prompt placement

- Reworked the conversion overlay prompts into compact two-line `MENU / +2` and `DOWN / MISS` blocks so each prompt is narrower and easier to place beside the physical buttons.
- Added geometry-aware prompt placement in `RugbyTimerOverlay.mc`: the left X offset is now derived from the visible bezel edge at the prompt's Y coordinate, which keeps the labels inside the usable area on different round Garmin screen sizes instead of relying on one fixed gutter percentage.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (existing container-analysis warnings and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Immediate persistence and manifest cleanup

- Added a model-level `persistState()` helper and routed score, card, pause/resume, and autosave writes through it so the latest match changes are written immediately instead of waiting for the next 5-second autosave window.
- Updated app stop handling to save any live match snapshot before exit, disable location events defensively, and close the current activity-recording segment cleanly. Activity recording now falls back to `SPORT_GENERIC` when needed and safely no-ops on devices without `ActivityRecording`.
- Removed the dead adjust-score menu classes and replaced the invalid manifest product ids with compiler-accepted targets, which clears the old manifest/device-id warnings on the validated Fenix builds.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (manifest/device-id warnings are gone; existing container-analysis warnings and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).
- Attempted `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-vivoactive5.prg -d vivoactive5 -y /Users/600171959/developer_key -w`, but the local SDK Java wrapper aborted with `Abort trap: 6`, so that target is in the manifest but could not be verified on this machine.

## [2026-03-30] Route menu hold to settings

- Added explicit `KEY_MENU` hold detection in the main delegate so holding the menu button on the timer view opens the app settings screen directly instead of falling through to the normal short-press match menu.
- Replaced the crashing `Adjust Score` main-menu item with `Settings`, so both short-press and long-press menu workflows now lead to safe settings access.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings, container-analysis warnings, and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Seed yellow card timers immediately

- Changed yellow-card creation to store an initial `remaining` value at the moment the card is logged, instead of relying on a later timer update before the renderer can show a live countdown.
- Hardened the card renderer and yellow-timer updater so they fall back to the configured card duration if an entry arrives without a computed `remaining` field.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings, container-analysis warnings, and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Guard overlay button actions

- Centralized conversion/penalty overlay actions behind one guarded delegate helper so make/miss/hide transitions all use the same safe path instead of duplicating logic across button handlers.
- Added defensive input guards around the main button handlers and an overlay action lock so one physical press cannot trigger duplicate state changes and crash the app.
- Replaced the stacked left-side conversion prompt block with shorter gutter-aligned `MENU +2` / `DOWN X` hints to keep the overlay clear of the countdown digits on round watches.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings, container-analysis warnings, and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Direct key handling for conversion overlay

- Added direct `onKey()` handling for conversion and penalty overlays so raw `KEY_MENU`, `KEY_UP`, and `KEY_DOWN` hardware events are consumed by the app instead of depending only on behavior mapping.
- Fixed the bottom main-screen hint to load real string resources instead of drawing numeric resource ids, which removes the stray `15779`-style labels.
- Tightened and repositioned the conversion overlay prompt block to avoid timer overlap on round screens, while shortening the labels to `MENU / MAKE` and `DOWN / MISS`.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings, container-analysis warnings, and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Route conversion make to Menu button

- Moved the conversion “made” action off the previous-page path and onto the actual `onMenu()` handler while the conversion overlay is visible, matching the physical `UP/MENU` button behavior on fenix-class watches.
- Conversion overlay presses from the old previous-page path are now ignored so the LIGHT button no longer accidentally records a made conversion.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings, container-analysis warnings, and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Fix conversion prompt labels

- Fixed the conversion overlay prompt block so the new `UP/MENU` and `DOWN` labels are loaded as actual strings instead of rendering their raw resource ids.
- Moved the conversion prompt text farther inward and slightly away from the top/bottom bezel so it no longer clips on round watch screens.

## [2026-03-30] Conversion overlay prompts and score menu cleanup

- Simplified the score-entry menu so it now offers only `Try (5)`, `Penalty Try (7)`, and `Drop Goal (3)`. Post-try conversions are no longer entered from a nested score menu.
- Recording a try now closes the score menus and immediately opens the conversion overlay, where `UP/MENU` records a made conversion and `DOWN` records a miss.
- Reworked the conversion overlay prompts so the make/miss instructions sit on the left edge next to the physical button positions instead of a single centered hint line.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings, container-analysis warnings, and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Freeze count-up clock until start/resume

- Changed saved-state restore so paused and halftime launches no longer rebuild a running `gameStartTime` immediately. The count-up timer now stays frozen when the app opens and only starts moving after the referee presses `Select` to begin or resume play.
- Updated resume logic to reconstruct `gameStartTime` from the saved `gameTime` baseline when play is explicitly resumed, so restored matches continue from the correct elapsed time instead of jumping or restarting.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings, container-analysis warnings, and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Haptics rollout and kickoff overlay removal

- Removed the timed kickoff overlay from the active match flow so conversions now return straight to live play instead of opening a second special-timer state; older saved kickoff states still deserialize safely through the persistence compatibility path.
- Added distinct haptic patterns for match start, pause, resume, half-time, full-time, lock toggle, conversion start/10-second warning/expiry, penalty start/10-second warning/expiry, and yellow-card warning/expiry.
- Updated the docs and app-store copy to describe the conversion/penalty-only special overlays and the expanded referee-focused vibration scheme.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings, container-analysis warnings, and the pre-existing `RugbySettings.mc` unreachable-statement warning remain).

## [2026-03-30] Countdown display sync

- Unified countdown display rounding across the main countdown, conversion/penalty/kickoff inline labels, and the special overlay so the special timers no longer appear to lag behind the primary match timer by a second on different screens.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings and longstanding container-analysis warnings remain).

## [2026-03-30] Match profile presets

- Added a profile layer (`7s`, `10s`, `15s`, `U19`, `Custom`) so the settings screen can switch between full preset bundles instead of only toggling a `7s` boolean and per-type half lengths.
- Refactored the model and persistence to use active `conversionTime` / `kickoffTime` values plus a stored `matchProfileId`, while migrating older `rugby7s` and per-type timer keys into the new profile system without dropping existing custom setups.
- Rebuilt the settings UI around a `Profile` row, `Format Family`, a new `Kickoff Timer` row, and automatic promotion to `Custom` whenever the user manually edits a preset.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings and longstanding container-analysis warnings remain).

## [2026-03-30] Kickoff controls and idle button mapping

- Split kickoff timing by format so 7s keeps a 30-second restart window while 15s-format matches now use 60 seconds.
- Fixed the idle-screen button mapping so physical `UP` increases the half length and physical `DOWN` decreases it, matching the on-screen hint.
- Hardened kickoff overlay input by suppressing the main menu while special overlays are open and routing kickoff button presses away from the normal score/card flows so the overlay can be hidden or cancelled safely.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings and longstanding container-analysis warnings remain).

## [2026-03-30] Persistence and startup flow hardening

- Changed persistence so live matches are saved as resumable paused snapshots, with durable remaining-time serialization for yellow/red card timers plus undo history and event log entries preserved across app restarts.
- Reattached activity recording when play resumes after a saved session, removed the accidental penalty-kick countdown trigger from yellow/red card events, and wired `Lock on Start` so it now actually locks the watch at kickoff and second-half start.
- Aligned settings defaults and live updates: `Penalty Timer` now defaults consistently to off, and the conversion/penalty/lock toggles update the in-memory model immediately instead of waiting for an app restart.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest device-id warnings and longstanding container-analysis warnings remain).

## [2026-03-30] Remove startup setup prompt

- Removed the launch-time game type / half-length setup flow so the app now opens directly on the main timer screen; the idle screen keeps the new `UP/DOWN` minute adjustment path instead of pushing the washed-out selector UI.
- Updated `RugbySettings.mc` so `Game Type` is also treated as idle-only setup, and toggling it while idle updates the live model immediately instead of waiting for an app restart.
- Refreshed `README.md` and `project_technical_document.md` to describe the direct-to-timer startup flow and the new “Settings for 7s/15s, buttons for minute edits” behavior.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (existing manifest/device-id warnings and pre-existing container-analysis warnings remain; no new compile errors from this change).

## [2025-12-31] Documentation, icon, and build sync

- Resized `resources/drawables/icon.jpg` down to 40×40 so the launcher asset now matches Garmin's requirements and no longer triggers the scaling warning.
- Rewrote `README.md` with the latest workflow/feature summary and trimmed `AGENTS.md` to the requested 200‑400 words with sections for architecture, commands, testing, and the “one commit per change” rule; added a release workflow note to `project_technical_document.md`.
- Ran the signed build via `java --% -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar C:\Users\aliel\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.3.0-2025-09-22-5813687a0\bin\monkeybrains.jar -o bin\rugbytimer.prg -f monkey.jungle -y developer_key -d fenix6_sim -w` so the PRG updates (warnings about container access detection remain but the build succeeds).

## [2025-12-14] Watch status icons and renderer/layout sync

- Added small play/pause/lock icons to `resources/drawables/` and wired them into the renderer so watch faces show the current state (play vs paused/idle) plus a lock badge above the scores.
- Documented the new icon anchoring math (`iconY` and top insets) in `project_technical_document.md` to keep layout notes current.
- Loaded the new icons via `WatchUi.loadResource` to avoid the `WatchUi.BitmapResource` type error, keeping draws safe on all devices.
- Built via `java --% -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar C:\Users\aliel\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.3.0-2025-09-22-5813687a0\bin\monkeybrains.jar -o bin\rugbytimer.prg -f C:\Users\aliel\Projects\rugby-timer\monkey.jungle -y C:\Users\aliel\Projects\rugby-timer\developer_key -d fenix6_sim -w` (warnings about container access and unreachable statements remain in renderer/cards/event log but the build succeeds).
## [2025-12-12] Render/timing syntax & icon fix

- Removed the invalid local-type annotations and constructor return types so the renderer/timing modules now follow Monkey C's inferred typing rules and compile correctly.
- Regenerated `resources/drawables/icon.jpg` as a 40×40 launcher asset so the Fenix 6 no longer reports scale warnings.
- Verified the build via `& 'C:\Users\aliel\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.3.0-2025-09-22-5813687a0\bin\monkeyc' -f monkey.jungle -o bin\rugbytimer.prg -y developer_key -d fenix6`.

## [2025-12-12] Delegate constructors

- Removed the lingering `as Void` return types from the `initialize` constructors in `RugbyTimerDelegate` so the delegate compiles cleanly, and reran the same `monkeyc` build to confirm the fix held.

## [2025-12-12] Type imports & delegate helpers

- Added the missing `Toybox.Lang`, `Toybox.Application`, `Toybox.Position`, and `Toybox.System` imports across the helper modules so `Number`, `String`, `Array`, `Dictionary`, and `Application` resolve without compiler errors.
- Restored typed implementations for `ExitMenuDelegate` and `EventLogDelegate`, and aligned the GameType prompt/event log classes with the expected fields/methods, then rebuilt via the same `monkeyc` invocation.

## [2025-12-12] Constructor cleanup

- Removed the remaining `as Void` annotations from the GameType/EventLog constructors so Monkey C treats them correctly as constructors, then rebuilt with the usual `monkeyc` command to confirm the warnings disappear.
- Logged the monkeybrains build command to reflect the current packaging workflow and noted the remaining launcher icon warning.

## [2025-12-12] Countdown-aligned discipline timers

- Synced the red/yellow timers with the core countdown by calculating the actual countdown delta (`previousCountdownRemaining - countdownRemaining`) and feeding that into every card timer update so the cards only decrement while the main clock moves. Verified this flow via the same Java `monkeybrains.jar` build command (still reporting the launcher icon warning).

## [2025-12-12] Syntax verification & docs maintenance

- Reviewed every Monkey C module to understand the multi-module layout helpers (`Renderer`, `Cards`, `Timing`, `Overlay`, `Persistence`, `EventLog`) so I could keep updates consistent with the desired behaviors.
- Compiled the app via `& 'C:\Users\aliel\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.3.0-2025-09-22-5813687a0\bin\monkeyc' -f monkey.jungle -o bin\rugbytimer.prg -y developer_key -d fenix6` to ensure Monkey C syntax is clean across all source files.
- Updated `AGENTS.md` to codify the “atomic commit per change” and documentation expectations plus the event log/overlay hints, refreshed `project_technical_document.md` to explain `baseTimerY/candidateTimerY`, layout math, and multi-device targets, and captured this session in `log.md`.

## [2025-12-11] Renderer refactor and docs

- `RugbyTimerView` now delegates all score/timer/card drawing and layout math to `RugbyTimerRenderer`, keeping the view focused on state updates and overlays while ensuring the countdown positioning math stays centralized.
- Added inline documentation around the renderer's candidate/limit/min timers so future agents understand why `countdownY`, `stateY`, and `hintY` stay spaced based on the card stack and reserved state area.
- Updated `README.md`, `project_technical_document.md`, and `AGENTS.md` to mention the renderer helper and the documentation expectations; no manual compile was run because the environment is edit-only.

## [2025-12-12] Timer/persistence/overlay modules

- Pulled the scoring overlay drawing, countdown math, and haptics into `RugbyTimerTiming.mc`, so the update loop sits outside the view and just orchestrates what state changes happen.
- Created `RugbyTimerPersistence.mc` for `saveState`, `loadSavedState`, and `finalizeGameData`, keeping the view’s persistence logic centralized and shareable.
- Added `RugbyTimerOverlay.mc` to draw the inline conversion/penalty/kickoff overlay, handle hints, and keep the view focused on state updates, plus noted the new helpers in `AGENTS.md` and `project_technical_document.md`.

## [2025-12-31] Countdown overlay polish

- The inline overlay now labels the primary countdown timer, keeps it white, and places the conversion/kickoff/penalty timer squarely in the middle so the referee sees both clocks.
- The special timer confirmation text is larger and still appears briefly when the referee confirms a conversion.

## [2025-12-12] Modular cards and event log helpers

- Created `RugbyTimerCards.mc` to house the yellow/red timer math, numbering helpers, and card-stack resets so the view no longer kept that entire block of logic.
- Added `RugbyTimerEventLog.mc` to format/export the event log text and keep the `EVENT_LOG` wiring out of the main view; the view now just orchestrates the helper and a few thin wrappers.
- Updated the documentation to call out the new helper modules so future contributors know where the card and log behaviors live.

## [2025-12-28] Special timer alert

- Added a 15-second vibration for conversion/penalty/kickoff countdowns so referees are alerted ahead of the kick window.
- Reset the alert flag whenever those timers start so the notification only fires once per phase.

## [2025-12-29] Conversion overlay shortcuts

- When the conversion overlay is visible, the UP button logs a successful kick and adds two points while the DOWN button records a miss, and the onscreen hint updates to remind the referee which buttons perform which action.
- The overlay now renders the conversion countdown in the center (with the main countdown above it, both using the same high-contrast color) and flips the hint text order so the DOWN prompt appears before UP, matching the new layout focus.

## [2025-12-28] Special timer screen and save option

- Save Game now appears in the Exit dialog, writing the current match summary via `saveGame()` so referees can capture the state without ending play.
- Conversion/Kickoff/Penalty states now display the label and countdown as an inline overlay drawn over the scoreboard; the overlay closes automatically before each scoreboard interaction while maintaining the existing UP/DOWN shortcuts.

## [2025-12-30] Conversion overlay countdown & confirmation

- The overlay now shows the running countdown timer above the conversion/kickoff/penalty label so referees retain visibility into the main clock while the special timer is active.
- Registering a conversion via the overlay’s UP button shows “Conversion recorded” on-screen briefly to confirm the score update.

## [2025-12-28] Protect countdown layout

- Added inline documentation for the timer stack math in `source/RugbyTimerView.mc` and clamped `countdownY` to keep the big clock away from the state/hint block while still staying above the card timers.
- Noted the adaptive timer geometry and multi-platform coverage in `project_technical_document.md` and `README.md` so future agents understand the device scope and spacing guarantees.

## [2025-12-27] Highlight conversion text



- Added cover.jpg (512x512, <300 KB) for the Connect IQ Store listing so the app has a compliant cover image alongside the launcher icon.







- Rendered the CONVERSION/KICKOFF/PENALTY labels in high-contrast red to keep them legible against the countdown display.





## [2025-12-27] Avoid timer overlap





- Raised the state text when the countdown timer is high so the conversion/penalty/KICKOFF captions never intersect the white countdown digits; the computed `stateY` and `hintY` now depend on the adjustable `countdownY`.





## [2025-12-27] Trim manifest targets





- Removed the unsupported Forerunner/Venu/Instinct product IDs because the SDK rejected them and documented that the app currently targets Fenix 6/7 plus Epix/Venu in the README.





## [2025-12-26] Expanded product list





- Added the Fenix 7/7S families plus Epix, Forerunner 745/945/255/955, Venu 2/3, and Instinct 2 identifiers to `manifest.xml` and noted the expanded coverage in `README.md` so the app can build for more Garmin watches.





## [2025-12-26] Launcher icon swap





- Replaced the 40?40 PNG launcher icon with `icon.jpg` and pointed `resources/drawables/drawables.xml` at it so the watch delivers the requested asset.





# Session Log





## [2025-12-24] Multi-platform readiness





- Added Fenix 7, Epix, Forerunner 745/945, and Venu 2 to `manifest.xml`, refreshed `README.md`, and noted the wider device coverage so branches can target additional watch families beyond the Fenix 6 lineup.





## [2025-12-24] Pause countdown in set-piece states





- Select toggles pause/resume even during conversions, penalties, and kickoff so the countdown timer can be frozen while those special windows run.





# Session Log





## [2025-12-23] Card counter persistence





- Ensured yellow/red card counters persist via `cardId` metadata, tracked total tallies per team, and reset the timers plus totals when a match finishes so the Y# labels always reflect the total cards issued rather than whether an earlier timer is active.





## [2025-12-22] Event Log relocation





- Moved the Event Log entry out of the main menu and into the Back/Exit menu so referees can access it via the BACK/LAP dialog while the game is running, and hooked the Exit menu item up to `view.showEventLog()`.





## [2025-12-10] Timer layout and docs





- Documented the timer geometry (game clock vs countdown vs card stack) and ensured yellow timer dictionaries carry their `Y#` labels so card logic stays predictable while the running game timer keeps counting even when the countdown is paused.



- Added the 40x40 launcher icon, refreshed `resources/drawables/drawables.xml`, and updated `AGENTS.md` and `project_technical_document.md` so contributors understand the layout and activity recording behavior.



- Verified the build via `monkeyc -f monkey.jungle -o bin\rugbytimer.prg -y developer_key -d fenix6`.





- Shifted the countdown timer above the card stack and capped its position to stay clear of the "PAUSED" prompt, ensuring the card and hint blocks never overlap the primary clock readout.



- Added a kickoff shortcut so the scoreboard button clears the kickoff timer and immediately resumes normal play, keeping the UI responsive during restart sequences.



- Added a menu-driven Event Log that records score/card timestamps and a "Save Log" action that writes the human-readable timeline to Storage for sharing after the match.



- Cleared card timers and red/yellow state whenever a game ends or is reset so stale discipline indicators cannot linger on subsequent matches.







## [2025-12-11] Score Spacing Fix































- Lowered the tries indicators in `source/RugbyTimerView.mc` so they no longer overlap the main score digits on the Fenix 6 layout.































































## [2025-12-12] Try Placement Refinement































- Shifted `triesY` to `height * 0.36` in `source/RugbyTimerView.mc` to add more breathing room under the scores and keep the try text clear of the digits.































- Updated `triesY` to sit just below the half indicator and switched to a centered `homeT/awayT` string so the try info lives between the scores without duplicating text on each side.































































## [2025-12-13] Revert card/main timer layout































- Rolled the card timer / main timer layout back to the pre-layout-refactor implementation so the spacing resembles the earlier stable state, only keeping the centered `homeT / awayT` text beneath the half indicator.































































## [2025-12-14] Swap timer roles































- Flipped the main/secondary timer text so the countdown timer now occupies the primary (white) position while the game clock moves to the lower slot with the dim/red accent color.































































## [2025-12-15] Keep gameTimer running when countdown pauses































- Adjusted `updateGame` so `gameTime` keeps counting even while countdown actions are suspended (e.g., paused), while `countdownRemaining` only ticks during active phases.































































## [2025-12-16] Cap card timers & yellow warning































- Display-only the first two yellow timers per side so extras keep tracking silently until earlier timers finish, then reveal their remaining time once space frees up.































- Added a one-time vibration whenever any yellow timer drops below 10 seconds so the referee hears the countdown even when watching another part of the screen.































- Preserved each yellow entryâ€™s `Y#` label so replacing a card that was hidden still shows the same identifier when it finally appears.































































































## [2025-12-17] Fix label parsing































- Replaced the unsupported `substr` call in `parseLabelNumber` with a manual loop that drops the leading “Y”, preventing the undefined symbol build error on Fenix 6.















































































## [2025-12-18] Clarify timing math















- Documented what `timerY`, `countdownY`, and the card stack offset calculations represent so future contributors understand how card/padding adjustments affect the running timers.







































## [2025-12-19] Expand inline documentation







- Added concise comments before initialization, timer math, scoring/card helpers, persistence, and recording sections so the intent is clear for future maintainers.



















## [2025-12-20] Conversion button shortcuts



- Score/card hardware buttons now double as conversion decisions when the conversion timer is running, so the correct team records a made kick or the conversion timer is terminated on a miss.



- Introduced `conversionTeam` state persistence to remember which side triggered the conversion, keeping the buttons deterministic through loads/resumes.









## [2025-12-21] Decouple timers

- Moved the running game timer above the “Half #” label and kept the countdown clock down below with its own position logic so the two clocks stay separate.



## [2025-12-10] Layout Resilience































- Reworked `RugbyTimerView` so the half text, tries, and timers position themselves without overlapping even when multiple card timers are active, and card timers now space dynamically below the main clocks.































- Noted the adaptive layout strategy in `project_technical_document.md` so future contributors understand the spacing guarantees.































- Rebuilt with `monkeyc` to confirm the refreshed layout compiles cleanly for the Fenix 6.































































## [2025-10-31] Feature/Enhancement Summary































- Added persistent state storage and final match summary for reuse by future agents.































- Reworked UI to display multiple yellow/red timers with numbering, auto shift main timers to avoid overlap, and maintain layout across device resolutions.































- Introduced card dialog via hardware buttons (up/down), conversion-specific score options, and pause clock capability.































- Added 30-second countdown alert via Attention vibrate profile and ensured timers keep running during conversion/penalty states.































- Documented project in `project_technical_document.md` for onboarding future LLM collaborators.



































- Ensured kickoff states keep updating countdownRemaining while their special countdown window runs so the main timer never freezes during conversions, penalties, or kickoff phases.





- Added a menu-driven Event Log that records score/card timestamps and a "Save Log" action that writes the human-readable timeline to Storage for sharing after the match.

- Fixed the exit menu invocation so selecting Event Log pops the dialog before pushing the log view, ensuring the log actually appears instead of being popped immediately.
