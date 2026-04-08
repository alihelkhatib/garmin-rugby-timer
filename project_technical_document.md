# Project Technical Document

## Overview
- Repository: `rugby-timer`
- Language: Monkey C (Garmin Connect IQ)
- Target platforms: compiler-validated Garmin fēnix 6/7/8/E families plus vívoactive 5/6, with related tactix/quatix/Enduro variants covered where Garmin maps them onto the same Connect IQ product ids.
- Purpose: Rugby match timing, scoring, discipline tracking, GPS `SPORT_RUGBY` recording, overlay dialogs for conversions/penalties, event logging, and data persistence/export.
- Canonical UI reference: `docs/UI_SPEC.md` is the decision-complete contract for the live match screen. It defines priority order, band ownership, card-urgency visibility rules, safe-area expectations, and review-blocking layout invariants for future visual work.

## Architecture
- `RugbyTimerApp.mc`: App entry point and provider for the main view/delegate pair.
- `RugbyGameModel.mc`: Public match-state facade. It owns canonical state, one-shot status messages, the 300 ms debounce timers for live snapshot saves and custom-profile writes, and delegates most rule changes to focused services.
- `RugbyClockService.mc`, `RugbyScoringService.mc`, `RugbyDisciplineService.mc`, `RugbyRecordingService.mc`: Business-rule helpers for clock transitions, score history, discipline flows, and GPS recording. Snapshot orchestration now stays directly in `RugbyGameModel` because the removed `RugbySnapshotService` was only adding call depth.
- `RugbyTimerPersistence.mc`: Saves/restores `gameStateData`, `eventLog`, and `lastGameSummary`; discards malformed snapshots on load; finalizes post-match summaries; and remains the only module that writes live match snapshots to Storage.
- `RugbyScoringService.mc`: Owns score-history payload normalization for persisted `lastEvents`. Stored events now use plain serializable dictionaries with string keys and values, while legacy symbol-based payloads remain readable for backward compatibility.
- `RugbyTimerEventLog.mc`: Owns event-log payload normalization and formatting. Stored entries now persist as `{ "time" => "MM:SS", "description" => String }`, and legacy `:time` / `:desc` payloads are still accepted on restore/display.
- `RugbyTimerDelegate.mc`, `RugbyTimerMenus.mc`, `RugbyTimerInputSupport.mc`: Handle hardware input, menu navigation, and pure button-routing rules. Idle UP/DOWN edits now bypass the broader action throttle so timer changes feel immediate on the watch.
- `RugbyTimerView.mc`, `RugbyTimerRenderer.mc`, and `RugbyLayoutSupport.mc`: the view now chooses a device-family XML layout for either the main screen or the special overlay, caches drawables by stable IDs, and binds runtime text/color/visibility into those XML-owned elements on each update. `RugbyTimerRenderer` now owns presentation mapping only, not screen geometry.
- `RugbyTimerTiming.mc`, `RugbyTimerCards.mc`, `RugbyTimerOverlay.mc`: Own shared timing loops, sanction timer math, and overlay-specific label/hint mapping.
- `RugbySettingsMenu.mc`, `RugbySettingsNavigation.mc`, `RugbySettingsPickers.mc`, `RugbySettingsSupport.mc`, `RugbyMatchProfiles.mc`: Own idle-only configuration, preset selection, picker helpers, and custom-profile persistence/migration.
- Boundary types that still add value: `MatchProfileEntry.mc`, `CardEntry.mc`, `MatchSummaryEntry.mc`, `PersistedGameSnapshot.mc`, `PersistedCardTimerEntry.mc`, and `RugbyTimerRenderTypes.mc`.
- Validation tooling: `scripts/run-tests.sh` builds the test PRG and prints the correct simulator command; `scripts/validate-local.sh` builds both the app PRG and test PRG in one step.

## Layout Notes
- The live match screen is now XML-first. Each device family (`compact_round`, `large_round`, `rect`) has a dedicated main layout plus a dedicated overlay layout in `resources/layouts/layout.xml`.
- Layout XML now owns the positions of scoreboard labels, sanction slots, countdown text, state lines, hint lines, and overlay text. Runtime code updates those drawables through `findDrawableById()` instead of recomputing Y positions every frame.
- The main layouts reserve a permanent sanction row under the header. Home and away sanction slots are always part of the layout and are simply hidden when no urgent sanction or permanent red needs to be shown.
- `RugbyTimerRenderer` now provides content decisions only: elapsed/countdown/half/tries strings, state-line text/color, hint mode, icon choice, and urgent sanction selection.
- Compact round keeps the lower-priority chrome lighter by hiding tries and the two corner icons, while larger families keep those elements visible.
- Overlay layouts fully replace the main layout when the conversion or penalty overlay is active. Overlay text is bound through XML just like the main screen.
- Garmin's layout schema on this SDK still does not allow positioned bitmap drawables in layout XML, so the play/pause and lock icons remain the only small elements still drawn directly in code.

## Key Behaviors
- Idle setup: the app opens directly on the main timer screen. UP/DOWN change the half length immediately, MENU also increments the idle timer, and holding UP or MENU opens the preset picker.
- Idle-hint visibility is now a simple persisted watch setting. Hints default to on, use a smaller compact-round font tier, and can be disabled for a cleaner idle screen without changing gameplay behavior.
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
