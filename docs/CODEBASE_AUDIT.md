# Codebase Audit

## Status
- Build target compiles successfully on `fenix6`.
- Unit-test target compiles successfully with Garmin `--unit-test`.
- Current module split is broadly correct: view/rendering, timing, cards, persistence, settings, and profiles are separated better than a typical single-file Connect IQ app.

## Concrete fixes applied
- `scripts/run-tests.sh` now builds tests with `--unit-test`; previously the Garmin SDK stripped the `(:test)` methods.
- Custom profile labels now persist via Storage instead of always reloading as `Custom`.
- `Profiler.ENABLED` now defaults to `false` so the release/debug build does not pay continuous per-frame profiling overhead unless explicitly enabled.
- `RugbyGameModel` now delegates to focused services instead of owning every transition directly.
- Settings/profile/event-log parsing now uses small typed helpers (`MatchProfileEntry`, `ScoreEvent`, `EventLogEntry`, `RugbySettingsSupport`) instead of adding more raw dictionary access in newly touched code.
- `RugbySettings` was split into menu/navigation/picker files, and `RugbyTimerDelegate` now keeps its menu classes in a separate `RugbyTimerMenus` module.
- `RugbyTimerInputSupport` now holds the pure button-routing rules that were previously embedded directly in the delegate.
- Persistence/render/timing/view code now share typed adapters for persisted snapshots, serialized card timers, timer-update results, and render layout/font/card-info values instead of passing raw dictionaries through every layer.
- Storage keys are now centralized in `RugbyStorageKeys.mc` instead of being duplicated as raw string literals across profile/settings/persistence code.
- Activity recording is now intentionally forced to `Activity.SPORT_RUGBY`; the previous generic-sport fallback has been removed.
- Finalized match summaries now also use a typed wrapper (`MatchSummaryEntry`) instead of ad hoc summary-dictionary access in persistence/tests.
- Startup/reset live state is now centralized through `RugbyGameModel.resetMatchRuntimeState()`, reducing duplicated field-reset logic.
- Recording support/failure now surfaces through a one-shot model/view status message rather than only `System.println`.
- Runtime save/input/restore failures now reuse that same one-shot status channel so the watch shows a short notice instead of failing silently.
- Invalid saved-match snapshots are now self-healed by clearing the bad Storage payload and resetting the app to a safe idle state.
- `scripts/validate-local.sh` now provides a single local validation command that builds the app target and the unit-test target together.

## Test coverage status
- Covered well: profiles/settings rules, card numbering/timing, countdown formatting.
- Added now: live yellow-card pause behavior, persisted live-match restore behavior, finalized summary/event-log persistence.
- Still manual-only: simulator UI rendering/layout overlap, device GPS/session behavior, vibration pattern validation.
- Still manual-only: visual confirmation of on-watch status-message timing/placement and full simulator end-to-end pass/fail reporting from `monkeydo`.

## Organization assessment
- Good: `RugbyTimerRenderer`, `RugbyTimerTiming`, `RugbyTimerCards`, and `RugbyTimerPersistence` are the right extraction points.
- Weak point: `RugbyGameModel.mc` is still the main maintenance hotspot because it mixes clock state, scoring rules, discipline rules, activity recording, undo, and lifecycle persistence orchestration.
- Improvement made: the highest-risk parts of `RugbyGameModel` are now split into `RugbyClockService`, `RugbyScoringService`, `RugbyDisciplineService`, `RugbyRecordingService`, and `RugbySnapshotService`, with the model left as a facade.
- Improvement made: `RugbySettings` is no longer a single large file, and `RugbyTimerDelegate` is reduced to the behavior/input delegate plus its direct helpers.
- Improvement made: several `RugbyTimerDelegate` rules are now unit-testable without WatchUi because they live in `RugbyTimerInputSupport`.
- Naming is partially standardized but still mixed:
  older core modules use `RugbyTimer*`, while the extracted debt-reduction modules now use `Rugby*Service`.
- The next naming cleanup should standardize around:
  `Rugby*Service` for orchestration/business logic and `RugbyTimer*` for UI/runtime helper modules.
- The next structural hotspots after `RugbyGameModel` are:
  `RugbyTimerDelegate.mc`, because it still combines hardware input mapping, overlay routing, idle-minute editing, and higher-level navigation logic.
- File-necessity review: there are no obvious dead source files left. The very small wrapper files are deliberate boundary types, not accidental fragmentation.
- Documentation review: source and test `.mc` files now include top-of-file purpose preambles, which improves maintainability and handoff clarity.

## Refactor proposal
1. Split `RugbyGameModel.mc` into focused services:
   `MatchClockService`, `ScoringService`, `DisciplineService`, `RecordingService`, `SnapshotService`.
2. Centralize all Storage keys in one module:
   eliminates string duplication and reduces migration mistakes.
3. Replace raw timer/profile dictionaries with typed wrappers at module boundaries:
   reduces compiler container-analysis warnings and makes tests less brittle.
4. Move settings-menu action logic into pure helper functions:
   easier unit coverage without UI delegates.
5. If naming cleanup is desired later, do it in one intentional batch rather than gradually:
   `RugbyTimerInputSupport` -> `RugbyInputRules`,
   `RugbyTimerMenus` -> `RugbyMatchMenus`,
   `RugbyTimerRenderTypes` -> `RugbyRenderModels`.

## Memory and smoothness priorities
1. Keep `Profiler` off by default.
2. Avoid new dictionary/string allocations in the render path where possible; the current renderer is mostly acceptable, but `RugbyGameModel` and persistence still create many ad hoc dictionaries.
3. Prefer typed objects (`CardEntry`, future `MatchProfileSnapshot`) over repeated dictionary cloning for frequently updated state.
4. Keep expensive persistence/event-log writes off the render path; current autosave cadence is acceptable, but any new features should not increase save frequency.
5. If more optimization is needed, profile only these hotspots first:
   `RugbyTimerTiming.updateGame`, `RugbyTimerRenderer.renderCardTimers`, `RugbyTimerPersistence.saveState`.

## Remaining Warning Reduction Targets
- Production warnings are now cleared on the app build.
- Remaining warning noise is limited to a small number of older tests that still access arrays/dictionaries directly.
- The highest-value next cleanup is converting the remaining warning-heavy tests to fully typed helpers, not more production refactoring.
