# Handoff Checkpoint

This file is a checkpoint of the work, findings, constraints, and open items discussed so far.

## Current Status
- Main app target compiles with the Garmin SDK on `fenix6`.
- Unit-test target compiles when built with `--unit-test`.
- Direct simulator test execution is not currently verified in this workspace because `monkeydo` returned `Unable to connect to simulator`, and attempting to launch the bundled `connectiq` app also failed in this environment.
- The worktree is dirty and already had in-flight local edits before the latest debt pass. Do not revert unrelated changes casually.
- The latest warning-reduction pass cleaned the newly touched profile/settings/event-log paths; the remaining warnings are now concentrated in older persistence/renderer/timing code plus two harmless profiler unreachable-branch warnings caused by keeping the profiler disabled by default.

## What Was Confirmed
- The repo already had a Garmin-style test scaffold, but the helper script was incomplete because it did not include `--unit-test`.
- The app is broadly organized better than average for a Connect IQ app:
  rendering, timing, cards, persistence, settings, and profile logic are split into separate modules.
- The largest maintainability hotspot is `RugbyGameModel.mc`, which had been carrying clock logic, scoring, discipline, recording, undo, and snapshot orchestration together.
- The biggest remaining compiler noise is from raw dictionary access and some pre-existing unreachable-statement warnings.

## Changes Already Made
- Fixed the unit-test build workflow in `scripts/run-tests.sh`.
- Added/expanded unit tests for persistence and model behavior.
- Persisted custom profile labels instead of always restoring `"Custom"`.
- Disabled the debug profiler by default for runtime smoothness.
- Added `docs/CODEBASE_AUDIT.md` with audit/refactor/performance notes.
- Added this `handoff.md` checkpoint document.
- Added typed wrappers and pure helpers for the recent debt passes:
  `MatchProfileEntry`, `ScoreEvent`, `EventLogEntry`, `RugbySettingsSupport`, `RugbyTimerInputSupport`,
  `PersistedGameSnapshot`, `PersistedCardTimerEntry`, `PersistedStatePair`, `RugbyTimerRenderTypes`,
  `MatchSummaryEntry`.
- Added `RugbyStorageKeys` so persistence/profile/settings code now shares one source of truth for Storage key names.
- Split the old `RugbySettings.mc` monolith into focused files:
  `RugbySettingsMenu.mc`, `RugbySettingsNavigation.mc`, `RugbySettingsPickers.mc`.
- Extracted the menu/delegate classes out of `RugbyTimerDelegate.mc` into `RugbyTimerMenus.mc`, leaving `RugbyTimerDelegate.mc` focused on hardware input and high-level navigation.
- Activity recording is now forced to `Activity.SPORT_RUGBY` with no generic-sport fallback. On devices/runtime environments that do not support rugby activity recording, the timer still runs but recording is skipped.
- `RugbyGameModel` now has a canonical `resetMatchRuntimeState()` path so startup and manual reset do not duplicate live-state initialization logic.
- Unsupported/failing rugby activity recording now surfaces a one-shot UI status message through the view instead of only printing to logs.
- Runtime failures now use a shared one-shot status channel instead of the old recording-only path, so save/input/restore failures can surface on-watch too.
- Malformed saved snapshots are now treated as invalid, cleared from Storage, and replaced with a safe idle reset plus a short user-visible notice.
- Added `scripts/validate-local.sh` as the single local validation entrypoint; it builds the app target and the unit-test target and then points at the correct `monkeydo <prg> <device_id> -t` command.
- Added integration-style Garmin tests for preset persistence, paused restore, sanction persistence, and strict rugby-recording startup in `tests/Test_RugbyIntegrationFlows.mc`.
- Split the remaining pure presentation rules out of `RugbyTimerView.mc` into `RugbyTimerViewSupport.mc`, with direct tests for overlay visibility, hint routing, and toast visibility.

## Debt Reduction Pass In Progress
- `RugbyGameModel` is being reduced to a facade.
- Logic is being extracted into focused helpers:
  `RugbyClockService`, `RugbyScoringService`, `RugbyDisciplineService`, `RugbyRecordingService`, `RugbySnapshotService`.
- Goal of this pass:
  preserve behavior and external call sites while making future changes safer and more testable.

## Test Coverage Snapshot
- Covered reasonably well:
  profile settings behavior, custom profile persistence, card numbering, sanction timing, summary persistence, paused restore behavior.
- Newly targeted in this phase:
  wrapper-level coverage for game start/pause/resume, scoring-to-conversion flow, undo, and save-game summary behavior.
- Still not fully automated:
  simulator UI layout assertions, stable real simulator test execution, GPS/session runtime behavior, vibration validation.
- Verification standard used in this checkpoint:
  all non-doc code changes should have unit-test coverage added or updated; compile success of the unit-test target is verified, but runtime pass/fail is still pending simulator availability.

## Important Constraints
- Avoid breaking existing storage key compatibility in this refactor pass.
- Avoid broad UI behavior changes during the service extraction.
- Avoid reverting unrelated local edits already present in the dirty tree.
- Keep docs and tests aligned with the actual verified state, not assumed state.

## Naming and Overlap Analysis
- Naming is not fully standardized yet.
- Current pattern split:
  `RugbyTimer*` modules mostly represent older runtime/UI helpers, while newer extracted modules use `Rugby*Service`.
- This is workable, but inconsistent.
- Best follow-on standard:
  reserve `Rugby*Service` for non-UI orchestration/services, reserve `RugbyTimer*` for UI/runtime presentation modules that are tied to the app/watch face behavior.
- Files that still bundle too many responsibilities:
  `RugbyTimerDelegate.mc` remains a hotspot because it still owns raw hardware-button handling, overlay action routing, idle-minute adjustments, and navigation transitions.
- Recent cleanup reduced that hotspot:
  the pure button-rule pieces now live in `RugbyTimerInputSupport`, which covers idle minute clamping, overlay key mapping, and hold-to-preset gating.
- `RugbySettings` is materially improved:
  pure logic is in `RugbySettingsSupport`, the menu is in `RugbySettingsMenu.mc`, navigation/delegates are in `RugbySettingsNavigation.mc`, and pickers are in `RugbySettingsPickers.mc`.
- Redundancy/overlap still present:
  `RugbyTimerTiming` and `RugbyClockService` now share adjacent responsibility boundaries,
  `RugbyTimerPersistence` and `RugbySnapshotService` are similarly adjacent,
  and the distinction is currently “low-level helper” vs “orchestration facade”.
- That overlap is acceptable for now, but if the codebase keeps evolving, those pairs should either be merged or renamed more explicitly.

## File Necessity Review
- No current source file looks dead or safely removable without reintroducing coupling.
- The smallest wrapper files (`PersistedStatePair`, `MatchProfileEntry`, `EventLogEntry`, `ScoreEvent`) are justified because they removed repeated raw-dictionary access and made unit tests clearer.
- `RugbyTimerMenus.mc` is large, but it is not redundant; it is the correct home for the match-menu stack that used to clutter `RugbyTimerDelegate.mc`.
- `RugbySettingsNavigation.mc` and `RugbySettingsPickers.mc` should stay separate because one owns navigation flow and the other owns reusable picker UI code.
- `Profiler.mc` remains worth keeping because it is disabled by default and still useful for targeted hotspot checks.
- File renames are not urgent enough to justify churn now. If a naming batch is done later, the highest-value candidates are:
  `RugbyTimerInputSupport` -> `RugbyInputRules`,
  `RugbyTimerMenus` -> `RugbyMatchMenus`,
  `RugbyTimerRenderTypes` -> `RugbyRenderModels`.

## Documentation Status
- All current `.mc` source files now include a top-of-file purpose preamble.
- Test `.mc` files now also include a file-level purpose preamble where they previously lacked one.
- The goal was maintainability, not comment volume: only file purpose and responsibility boundaries were standardized.

## Remaining Warning Hotspots
- The latest warning reduction pass cleaned up the newly introduced service/profile/settings/event-log warnings and reduced the card helper warnings to a small residual parsing path.
- Remaining source hotspots are now concentrated in:
  no production-warning hotspots remain after the latest cleanup; remaining warning noise is test-only dictionary access in a small number of older tests.
- `RugbyTimerPersistence`, `RugbyTimerTiming`, and `RugbyTimerView` were cleaned substantially by moving persisted snapshot data, timer-update results, and renderer layout/font/card info onto typed adapters.
- The remaining pattern is now mostly a small number of cache/container accesses and old unreachable-statement warnings.
- Best next warning-reduction targets:
  cleanup of the remaining string/container parsing in `RugbyTimerCards` and, only if worth the churn, replacing the renderer's internal cache dictionaries with a different cache mechanism.

## Recommended Next Steps After This Pass
1. Reduce the remaining responsibility load inside `RugbyTimerDelegate.mc` further by extracting any remaining view/model routing branches that can be separated without WatchUi coupling.
2. Clean the last few test-only container-analysis warnings in `Test_RugbyTimerCards_advanced`, `Test_RugbyTimerPersistence`, and `Test_RugbyTypedEntries`.
3. If simulator access becomes available, run `monkeydo ... /t` and update the checkpoint with actual runtime test results.
