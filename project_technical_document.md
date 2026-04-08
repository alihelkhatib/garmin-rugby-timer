# Project Technical Document

## Overview
- Repository: `rugby-timer`
- Language: Monkey C (Garmin Connect IQ)
- Target platforms: compiler-validated Garmin fēnix 6/7/8/E families plus vívoactive 5/6, with related tactix/quatix/Enduro variants covered where Garmin maps them onto the same Connect IQ product ids.
- Purpose: Rugby match timing, scoring, discipline tracking, GPS `SPORT_RUGBY` recording, overlay dialogs for conversions/penalties, event logging, and data persistence/export.

## Architecture
- `RugbyTimerApp.mc`: App entry point and provider for the main view/delegate pair.
- `RugbyGameModel.mc`: Public match-state facade. It owns canonical state, one-shot status messages, the 300 ms debounce timers for live snapshot saves and custom-profile writes, and delegates most rule changes to focused services.
- `RugbyClockService.mc`, `RugbyScoringService.mc`, `RugbyDisciplineService.mc`, `RugbyRecordingService.mc`: Business-rule helpers for clock transitions, score history, discipline flows, and GPS recording. Snapshot orchestration now stays directly in `RugbyGameModel` because the removed `RugbySnapshotService` was only adding call depth.
- `RugbyTimerPersistence.mc`: Saves/restores `gameStateData`, `eventLog`, and `lastGameSummary`; discards malformed snapshots on load; finalizes post-match summaries; and remains the only module that writes live match snapshots to Storage.
- `RugbyScoringService.mc`: Owns score-history payload normalization for persisted `lastEvents`. Stored events now use plain serializable dictionaries with string keys and values, while legacy symbol-based payloads remain readable for backward compatibility.
- `RugbyTimerEventLog.mc`: Owns event-log payload normalization and formatting. Stored entries now persist as `{ "time" => "MM:SS", "description" => String }`, and legacy `:time` / `:desc` payloads are still accepted on restore/display.
- `RugbyTimerDelegate.mc`, `RugbyTimerMenus.mc`, `RugbyTimerInputSupport.mc`: Handle hardware input, menu navigation, and pure button-routing rules. Idle UP/DOWN edits now bypass the broader action throttle so timer changes feel immediate on the watch.
- `RugbyTimerView.mc`, `RugbyTimerRenderer.mc`, `RugbyLayoutSupport.mc`, and `RugbyLayoutGuideDrawable.mc`: the view chooses a device-family XML layout in `onLayout()`, resolves the XML-backed layout guide, and passes that safe-area contract into the renderer. The renderer then owns the measured header/card/lower-band math and drawing. Idle, playing, and paused states share one consistent lower-band reservation model, so the main countdown stays vertically stable when a match starts, pauses, or shows active cards.
- `RugbyTimerTiming.mc`, `RugbyTimerCards.mc`, `RugbyTimerOverlay.mc`: Own shared timing loops, sanction timer math, and special overlay rendering/hints.
- `RugbySettingsMenu.mc`, `RugbySettingsNavigation.mc`, `RugbySettingsPickers.mc`, `RugbySettingsSupport.mc`, `RugbyMatchProfiles.mc`: Own idle-only configuration, preset selection, picker helpers, and custom-profile persistence/migration.
- Boundary types that still add value: `MatchProfileEntry.mc`, `CardEntry.mc`, `MatchSummaryEntry.mc`, `PersistedGameSnapshot.mc`, `PersistedCardTimerEntry.mc`, and `RugbyTimerRenderTypes.mc`.
- Validation tooling: `scripts/run-tests.sh` builds the test PRG and prints the correct simulator command; `scripts/validate-local.sh` builds both the app PRG and test PRG in one step.

## Layout Math Notes
- The match screen now uses a hybrid layout model: XML supplies per-family scaffolding and safe-area metadata, while Monkey C still measures and draws all live match text. This avoids trying to express dynamic score/card/countdown behavior in static XML.
- The renderer computes a safe content rect from the XML guide instead of anchoring to raw full-screen percentages. That is the watch-app-safe equivalent of using obscured-edge information here, since `getObscurityFlags()` is not a watch-app view API for this product type.
- The top scoreboard is a measured header band with separate rows for elapsed timer, team labels, score digits, half text, and tries text. Team labels live inside that reserved header band instead of being positioned by subtracting from the score Y.
- `candidateTimerY` is the preferred vertical anchor for the large countdown once visible card rows are accounted for. The renderer clamps the final `countdownY` between the measured header/card handoff and the reserved lower state/hint boundary inside the safe content rect.
- `stateY` and `hintY` define the lower text band for half/state text and hint copy. The renderer reserves those bands consistently between idle/playing and playing/paused, including when card rows are present, so the main countdown does not drift when those labels appear or disappear.
- The score band includes explicit `HOME` / `AWAY` labels above the score digits with team-distinct colors, but those labels are now placed from measured header rows inside the safe top band so they do not clip into round bezels.
- Card timers render in simple home/away columns under each score lane. Only the first two active sanctions per team are shown at once to keep the primary timer layout readable on round Fenix displays.
- Overlay screens keep the main countdown visible near the top and center the special timer below it so the overlay does not collide with the scoreboard.
- Card timers render as split rows with a compact colored label token (`Y1`, `R1`) and a separate same-color time/status field (`9:48`, `PERM`) around a shared anchor. The label and timer share the same compact font tier so the sanction clock is not visually downgraded relative to the label.

## Key Behaviors
- Idle setup: the app opens directly on the main timer screen. UP/DOWN change the half length immediately, MENU also increments the idle timer, and holding UP or MENU opens the preset picker.
- Match profile persistence: built-in presets (`7s`, `10s`, `15s`, `u19`) apply immediately. Manual timing edits promote the model to `custom`, but repeated idle edits now debounce their Storage writes so the watch is not writing on every button press.
- Snapshot persistence: score/card actions schedule a short debounced save instead of synchronously calling Storage every time. Lifecycle-critical paths such as start/pause/resume, halftime/full-time, explicit save/end/reset, and app stop flush pending writes immediately.
- Save-failure handling: the `Save failed` status is now reserved for true persistence exceptions. The previous constant-save failure caused by non-serializable score/event payloads was removed by normalizing stored payloads to plain serializable dictionaries.
- Resume behavior: reopening during a live match restores a paused snapshot with `pausedState` preserved, so the referee must explicitly resume play.
- Reset behavior: `resetMatchRuntimeState()` is the canonical live-state baseline used by startup and manual reset, which keeps clock/card/event initialization consistent.
- Conversion and penalty overlays stay synchronized with the same pauseable `gameTime` clock as the main countdown. The count-up clock is driven separately from `elapsedTime`.
- Discipline timing: yellow and timed-red sanctions run off `suspensionTime`, respect pause/resume correctly, and follow sevens-vs-non-sevens duration rules.
- Runtime status surfacing: recording failures, invalid saved snapshots, guarded input failures, and genuine save failures all share a one-shot status channel that the view surfaces briefly on-watch.
- GPS tracking: the app attempts `Activity.SPORT_RUGBY` only. If the device/runtime does not support rugby activity recording, the timer continues without crashing and surfaces a short status message.

## Persistence and Release Notes
- Keep persisted values storage-safe: only plain dictionaries, arrays, strings, booleans, and numbers should reach `Storage.setValue`.
- `resources/drawables/` includes the required 40×40 launcher icon; replacement assets must keep that size.
- Every gameplay change should be committed atomically and accompanied by `log.md` plus `project_technical_document.md` updates when behavior, persistence, layout, or release flow changes.
- Rebuild after source changes and record the command in `log.md`.
- Preferred local validation path: `./scripts/validate-local.sh`
- Simulator test command shape for this SDK: `"<SDK>/bin/monkeydo" "bin/tests.prg" "<device_id>" -t`
