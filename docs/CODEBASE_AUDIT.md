# Codebase Audit

## Status
- App and unit-test targets compile successfully on `fenix6`.
- `scripts/validate-local.sh` is the current one-command local validation entrypoint for building both PRGs.
- Simulator execution is reachable again through `monkeydo`, but this machine still does not provide a consistently captured terminal-visible full-suite result on every run, so compile-success is the only fully repeatable automated signal from this environment today.
- The current module split is intentionally conservative: rendering, timing, cards, persistence, settings, profiles, and a small set of rule-owning services are separated, but low-value wrapper layers were removed again.

## Concrete fixes applied
- `scripts/run-tests.sh` now builds tests with `--unit-test`; previously the Garmin SDK stripped the `(:test)` methods.
- `scripts/run-tests.sh` now prints the correct `monkeydo <prg> <device_id> -t` invocation for this SDK, and `scripts/validate-local.sh` restores the one-command local build validation path.
- Live snapshot payloads are now storage-safe plain dictionaries:
  `lastEvents` persist as `{ "type" => String, "isHome" => Boolean }` and `eventLogEntries` persist as `{ "time" => String, "description" => String }`.
- Snapshot/event-log loaders remain backward-compatible with the legacy symbol-keyed payloads, so existing saved data still restores cleanly.
- Score and card actions now debounce live snapshot saves for 300 ms instead of synchronously writing Storage on every mutation, and lifecycle-critical paths flush immediately.
- Custom profile edits now stay in memory briefly and flush on lifecycle boundaries instead of writing Storage on every idle minute tweak.
- Idle UP/DOWN timer edits now bypass the broader in-match action throttle and request an immediate redraw, which improves perceived button responsiveness on the watch.
- `RugbySnapshotService`, `ScoreEvent`, `EventLogEntry`, and `PersistedStatePair` were removed because they no longer owned enough behavior to justify extra files or call layers.
- Score-history payload shaping now lives in `RugbyScoringService`, and event-log payload shaping now lives in `RugbyTimerEventLog`.
- Custom profile labels now persist via Storage instead of always reloading as `Custom`.
- `Profiler.ENABLED` now defaults to `false` so the release/debug build does not pay continuous per-frame profiling overhead unless explicitly enabled.
- `RugbyGameModel` now delegates to focused services instead of owning every transition directly.
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
- Covered well: snapshot serialization compatibility, debounced persistence flushes, custom-profile write deferral, card numbering/timing, countdown formatting, and renderer layout anchoring.
- Added now: headless renderer-layout regression coverage for countdown anchoring and card-row-driven vertical spacing.
- Added now: score/card persistence regressions that specifically assert those actions do not surface `Save failed`.
- Added now: lifecycle flush coverage for pending snapshot saves and pending custom-profile writes on app stop.
- Added now: idle-key regression coverage that proves idle timer edits still apply even when the normal action gate is closed.
- Added now: live yellow-card pause behavior, persisted live-match restore behavior, finalized summary/event-log persistence, and legacy payload compatibility for event-log/score-history storage.
- Remaining regression gap: full simulator/UI rendering confirmation, on-watch haptics timing, and device GPS/session behavior still need manual smoke coverage on hardware.
- Still manual-heavy: full simulator UI rendering/layout overlap, device GPS/session behavior, vibration pattern validation.
- Still manual-only: visual confirmation of on-watch status-message timing/placement.

## Organization assessment
- Good: `RugbyTimerRenderer`, `RugbyTimerTiming`, `RugbyTimerCards`, and `RugbyTimerPersistence` are the right extraction points.
- Weak point: `RugbyGameModel.mc` is still the main maintenance hotspot because it mixes clock state, scoring rules, discipline rules, activity recording, undo, and lifecycle persistence orchestration.
- Improvement made: the highest-risk parts of `RugbyGameModel` are now split into `RugbyClockService`, `RugbyScoringService`, `RugbyDisciplineService`, and `RugbyRecordingService`, while the model keeps the small amount of snapshot orchestration that did not justify a standalone service.
- Improvement made: `RugbySettings` is no longer a single large file, and `RugbyTimerDelegate` is reduced to the behavior/input delegate plus its direct helpers.
- Improvement made: several `RugbyTimerDelegate` rules are now unit-testable without WatchUi because they live in `RugbyTimerInputSupport`.
- Naming is still intentionally mixed:
  `Rugby*Service` for business-rule helpers and `RugbyTimer*` for watch UI/runtime helpers.
- That split is acceptable for now; renaming should only happen in one intentional pass if it is ever prioritized.
- The next structural hotspots after `RugbyGameModel` are:
  `RugbyTimerDelegate.mc`, because it still combines hardware input mapping, overlay routing, idle-minute editing, and higher-level navigation logic.
- File-necessity review: there are no obvious dead source files left. The remaining small files all own clear behavior or a real boundary type.
- Documentation review: source and test `.mc` files now include top-of-file purpose preambles, which improves maintainability and handoff clarity.

## Refactor proposal
1. Keep the current conservative split:
   clock/scoring/discipline/recording as services, persistence and rendering as dedicated modules, and avoid reintroducing tiny pass-through services.
2. Keep persistence boundaries storage-safe:
   only plain dictionaries/arrays with serializable values should reach `Storage.setValue`.
3. Prefer behavior-owning helpers over wrapper files:
   if a helper only forwards one call or wraps a two-field dictionary, keep it in the owning module instead.
4. Continue moving pure delegate/settings rules into testable helpers when a real behavior boundary exists.
5. If naming cleanup is ever desired, do it as one intentional batch, not as opportunistic churn.

## Memory and smoothness priorities
1. Keep `Profiler` off by default.
2. Avoid synchronous Storage writes on hot button paths; the current 300 ms debounce window should stay the default unless device profiling proves otherwise.
3. Avoid new dictionary/string allocations in the render path where possible; the renderer is acceptable today, but it should remain mostly arithmetic and draw calls.
4. Keep expensive persistence/event-log writes off the render path and off repeated idle minute edits.
5. If more optimization is needed, profile only these hotspots first:
   `RugbyTimerTiming.updateGame`, `RugbyTimerRenderer.renderCardTimers`, `RugbyTimerPersistence.saveState`.

## Remaining Warning Reduction Targets
- Production warnings are now cleared on the app build.
- Unit-test builds are also warning-free after the XML layout regression helpers were updated to cast array entries explicitly before field access.
- The warning cleanup was intentionally narrow: it removed ambiguous container indexing without changing runtime behavior.
- The next cleanup priority should stay behavior-driven rather than warning-driven unless new compiler noise appears.
