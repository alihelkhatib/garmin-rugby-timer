## [2026-04-08] Rebalance compact-round header depth so the main countdown stays visible

- Corrected the compact-round layout math after the first hybrid safe-area pass proved too tall in practice. The root issue was that the center metadata (`Half 1`, tries) was being stacked below the score row, which made the measured header consume too much of a 240×240 screen and forced the main countdown off the bottom.
- `source/RugbyTimerRenderer.mc` now keeps the center metadata inside the score band on compact round layouts and reduces the minimum countdown gap under the header. When vertical space is tight, the countdown now prefers staying on-screen instead of preserving an idealized gap budget.
- Added `tests/Test_RugbyTimerRendererLayout.mc::test_mainContentLayout_keeps_idle_countdown_inside_safe_bottom` to lock the compact-round overflow regression down.
- Validated with `./scripts/validate-local.sh` on April 8, 2026. App build and unit-test build both passed.

## [2026-04-08] Separate the score band from center metadata

- Fixed a round-layout regression from the hybrid layout refactor where `Half 1` and `OT / OT` had been packed back into the score band, letting the big score digits and idle countdown visually collide on-device.
- Updated `source/RugbyTimerRenderer.mc` so the score row gets its own reserved band before the center metadata, and added a renderer regression in `tests/Test_RugbyTimerRendererLayout.mc` to keep the center metadata out of the score lane.
- Validated with `./scripts/validate-local.sh` (app build and unit-test build both passed).

## [2026-04-08] Introduce hybrid XML layout scaffolding and safe-area renderer bands

- Replaced the placeholder `resources/layouts/layout.xml` shell with three device-family layouts: compact round, large round, and rectangular. Each layout now carries a `RugbyLayoutGuideDrawable` instance so the watch app can pull family-specific safe-area and band-spacing metadata from XML during `onLayout()`.
- Added `source/RugbyLayoutSupport.mc` and `source/RugbyLayoutGuideDrawable.mc` so `RugbyTimerView` can choose the correct XML layout, resolve a fallback-safe guide when needed, and hand one stable layout contract into `RugbyTimerRenderer`.
- Refactored `RugbyTimerRenderer.mc` and `RugbyTimerRenderTypes.mc` to use a measured safe content rect plus explicit header/card/lower-band anchors instead of the older full-screen percentage guesses. `HOME` / `AWAY`, scores, elapsed timer, and sanction rows now all anchor inside the same safe layout model.
- Kept dynamic content in Monkey C rather than XML: live scores, card timers, the main countdown, and state text are still rendered procedurally, but now inside XML-defined family bands.
- Added layout regressions in `tests/Test_RugbyTimerRendererLayout.mc` and new family/fallback coverage in `tests/Test_RugbyLayoutSupport.mc`.
- Validated with `./scripts/validate-local.sh` on April 8, 2026. App build and unit-test build both passed. `monkeydo` was launched with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeydo" "bin/tests.prg" "1" -t`, but this environment still did not stream test-case results back to the terminal.

## [2026-04-08] Add explicit home and away score labels

- Added `HOME` and `AWAY` labels above the respective score digits in `source/RugbyTimerRenderer.mc` so the score columns are easier to parse at a glance on-watch.
- Used distinct team colors for the labels and measured their vertical offset from the score digits so they sit cleanly between the top icon row and the main score band instead of relying on a hardcoded visual nudge.
- Updated `project_technical_document.md` to document the new score-band readability treatment.
- Validated with `./scripts/validate-local.sh` (app build and unit-test build both passed).

## [2026-04-08] Increase card-timer emphasis and lock paused layout with active cards

- Increased the effective readability of the sanction clock without changing the overall UI structure: the card value field now uses the slightly larger compact-font tier where available, and the timer/status text now matches the card color instead of switching back to white.
- Fixed the remaining non-hacky layout bug when pausing with active sanctions on screen. The root cause was that playing and paused states were still reserving different hidden lower-band heights once card rows existed, so the countdown had two different legal anchors. The renderer now applies one shared lower-band reservation contract for idle/playing/paused.
- Expanded `tests/Test_RugbyTimerRendererLayout.mc` again with a playing-vs-paused-with-cards regression so the anchored countdown behavior is protected even when sanction rows are visible.
- Validated with `./scripts/validate-local.sh` (app build and unit-test build both passed).

## [2026-04-08] Stabilize paused countdown layout and improve card-timer readability

- Fixed the remaining countdown drift when pausing a match by reserving the same lower state-text band in `STATE_PLAYING` and `STATE_PAUSED`, matching the earlier idle/playing hint-band stabilization.
- Reworked sanction rows for easier on-watch scanning without a broad font-size increase: labels now render as compact colored tokens (`Y1`, `R1`) and the time/status value renders separately in white (`9:48`, `PERM`) around a shared column anchor.
- Slightly increased card row spacing and trimmed all rendered card labels to their compact canonical form so older stored labels with stray spaces still display cleanly.
- Expanded `tests/Test_RugbyTimerRendererLayout.mc` with a playing-vs-paused countdown-anchor regression test, and updated `project_technical_document.md` plus `tests/TEST_TRACEABILITY.md` to document the new layout/readability contract.
- Validated with `./scripts/validate-local.sh` (app build and unit-test build both passed).

## [2026-04-08] Stabilize persistence, debounce hot paths, and simplify snapshot plumbing

- Fixed the root cause of the persistent `Save failed` notice: live match snapshots now serialize score history and event log entries as plain Storage-safe dictionaries with string keys/values, while still accepting the older symbol-based payloads on restore.
- Debounced high-frequency Storage writes on the watch: score/card actions now coalesce snapshot saves for 300 ms, idle custom-profile edits now defer Storage writes until flush points, and lifecycle-critical paths (`start/pause/resume`, halftime/full-time, explicit save/reset/end, app stop) flush pending work immediately.
- Simplified the architecture without collapsing the whole app back into one file: removed `RugbySnapshotService`, `ScoreEvent`, `EventLogEntry`, and `PersistedStatePair`, and moved the tiny payload/orchestration logic into `RugbyGameModel`, `RugbyScoringService`, `RugbyTimerEventLog`, and `RugbyTimerPersistence`.
- Kept the main countdown visually stable when starting a match by reserving the same lower hint band in idle and playing states, and added `tests/Test_RugbyTimerRendererLayout.mc` to lock that regression down.
- Updated stale tests to the new debounced custom-profile behavior and added new regression coverage for save-failure removal, app-stop flushes, deferred custom-profile writes, and idle key-path responsiveness.
- Refreshed `docs/CODEBASE_AUDIT.md`, `tests/TEST_TRACEABILITY.md`, `tests/README.md`, and `project_technical_document.md` so the repo documentation now matches the simplified persistence/input architecture instead of the deleted wrapper layer.
- Validated with `./scripts/validate-local.sh` (app build and unit-test build both passed). Simulator execution is reachable again with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeydo" "bin/tests.prg" 1 -t"`, but terminal-visible full-suite output is still intermittent in this environment.

## [2026-04-08] Restore build validation path and add layout regression coverage

- Restored the missing `Hint_Select_Pause` string resource so both the app build and the unit-test build can compile again after the revert.
- Updated `source/RugbyTimerRenderer.mc` so idle and playing states reserve the same bottom hint space, keeping the main countdown vertically stable when the match starts.
- Added `tests/Test_RugbyTimerRendererLayout.mc` to cover countdown-anchor stability and card-row-driven vertical layout shifts without requiring the WatchUi runtime.
- Updated `scripts/run-tests.sh` to print the correct simulator command shape for this SDK and restored `scripts/validate-local.sh` as a one-command local validation entrypoint.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test"` (both passed).
- Ran `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeydo" "bin/tests.prg" 1 -t"` against the simulator. The harness now executes tests, but the suite is currently red: 21 passed, 27 failed, and 1 errored. The main failure clusters are profile/settings expectations, typed-wrapper round-trips, and persistence/card flows that hit `UnexpectedTypeException: Given value cannot be serialized`.

## [2026-04-03] Centralize storage keys and force rugby activity recording

- Added `source/RugbyStorageKeys.mc` and rewired active persistence/profile/settings/test helpers to use centralized Storage key names instead of repeating string literals.
- Removed the generic-sport activity fallback from `source/RugbyRecordingService.mc`. The app now attempts `Activity.SPORT_RUGBY` only; if rugby activity recording is unavailable in the runtime, the match still works but no recording session is created.
- Also cleaned the remaining card-label parsing path and removed the stale `ScoreEvent` state-pair helper that no longer matched the persistence architecture.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` (both passed).
- Residual production warnings are now limited to `source/Profiler.mc` and a few `source/RugbyTimerRenderer.mc` cache accesses. Test-only container warnings remain in older tests.

## [2026-04-03] Centralize live-state reset and expand regression coverage

- Added `source/MatchSummaryEntry.mc` so finalized `lastGameSummary` payloads are handled through a typed wrapper instead of repeated raw-dictionary access.
- Centralized live-state initialization/reset through `RugbyGameModel.resetMatchRuntimeState()`, and updated `RugbySnapshotService.resetGame()` to use that canonical path.
- Added one-shot recording-status feedback: unsupported/failing rugby activity recording now sets a model status message that `RugbyTimerView` surfaces briefly in the UI instead of only printing to logs.
- Reduced test warning noise by converting the older profile/summary tests to typed wrappers and added regression coverage for stored profile restore, preset switching, and custom settings mutation order.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` (both passed).
- Current warning state: no production warnings on the app build; remaining warnings are limited to a few test-only container accesses in `tests/Test_RugbyTimerCards_advanced.mc`, `tests/Test_RugbyTimerPersistence.mc`, and `tests/Test_RugbyTypedEntries.mc`.

## [2026-04-03] Simulator runtime test invocation reached app but not test execution

- Built the runtime test PRG with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o bin/tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` (passed).
- `monkeydo` from the sandbox still failed with `Unable to connect to simulator`.
- Re-ran `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeydo" "bin/tests.prg" /t` with elevated access against the running simulator. This time the simulator launched the PRG and printed `TestRunnerApp started. Use SDK unit-test runner to execute tests.`
- Current conclusion: simulator reachability is improved, but the runtime path is still not executing the `(:test)` suite. The current test harness/manifest entrypoint is launching the app shell rather than reporting test-case results.

## [2026-04-03] Correct monkeydo syntax discovered for this SDK build

- `monkeydo --help` in this SDK reports usage as `monkeydo executable device_id ... [-t]`, so the earlier `monkeydo <prg> /t` guidance was incomplete for this tool version.
- `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeydo" "bin/tests.prg" 1 /t` still failed because this macOS build rejects `/t` and expects `-t`.
- `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeydo" "bin/tests.prg" 1 -t` is accepted by the CLI and stays attached to the simulator, but it did not emit test-case results back to this terminal during the observed run window.
- Current conclusion: the CLI shape is now known (`device_id` plus `-t`), but this environment still does not provide a reliable terminal-visible pass/fail report from the running simulator.

## [2026-04-03] Clear remaining test-build warnings

- Replaced the last warning-heavy test array/dictionary indexing paths in `tests/Test_RugbyTimerCards_advanced.mc`, `tests/Test_RugbyTimerPersistence.mc`, and `tests/Test_RugbyTypedEntries.mc` with wrapper-based assertions and non-indexing access patterns.
- Rebuilt the unit-test target with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test"` and it now completes with `BUILD SUCCESSFUL` and no compiler warnings.

## [2026-04-03] Fix preset picker applying the wrong match format

- Root cause: `MatchProfileDelegate` was deferring preset application through a short timer after popping the picker view and was using symbol-style menu ids. On the real runtime this made the selection path more fragile than the headless tests suggested, and the chosen preset could fail to stick while the menu stack unwound.
- Fix: changed `MatchProfileMenu` to use stable string ids (`"7s"`, `"10s"`, `"15s"`, `"u19"`, `"custom"`) and changed `MatchProfileDelegate` to apply the selected profile synchronously before closing the picker.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` (both passed).

## [2026-04-03] Remove production warning noise and harden startup path

- Replaced the class-based storage-key access with plain top-level constants in `source/RugbyStorageKeys.mc` to avoid startup-time static initialization risk.
- Removed `RugbyTimerRenderer` layout caches to eliminate the remaining production container-analysis warnings.
- Converted `source/Profiler.mc` into an explicit no-op stub so disabled profiling cannot emit unreachable-statement warnings or affect runtime behavior.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` (both passed).
- Current state: no production warnings on the app build; remaining warnings are test-only dictionary-access warnings in older tests.

## [2026-04-03] Documentation preambles and naming review

- Added top-of-file purpose preambles across the remaining source and test `.mc` files so each module/test file now states why it exists before the implementation begins.
- Re-reviewed file necessity and naming consistency. No current source file appears dead or worth deleting; the small wrapper files remain justified because they reduce repeated raw-dictionary access and keep tests more focused.
- Captured the naming/file-necessity assessment in `handoff.md`, `docs/CODEBASE_AUDIT.md`, `project_technical_document.md`, and `tests/TEST_TRACEABILITY.md`.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` (both passed).
- Residual production warnings remain limited to `Profiler.mc`, `RugbyTimerCards.mc`, and `RugbyTimerRenderer.mc`; older test-only container warnings remain in some legacy test files.

## [2026-04-02] Release: Improved timing, overlays, export reliability, and polish

- Improved timer accuracy: fixed pause/resume desynchronization and reduced countdown drift so half and card timers stay accurate after pauses and long sessions.
- Overlay fixes: resolved stacking and display glitches for conversion, kickoff, and penalty overlays; overlays now show and dismiss predictably.
- Event-log export: fixed CSV formatting and edge-case failures—exports and sharing are more reliable.
- Compatibility: updated launcher icon to required 40×40 and adjusted layouts to prevent clipping on more devices.
- Performance & stability: reduced CPU usage during active timing and fixed intermittent slowdowns.
- Minor UI polish and general bug fixes.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (builds passed).

## [2026-04-01] Reapply the two-visible-card cap and align card display rounding

## [2026-04-01] Restore simple stacked card columns and number red cards

- Replaced the recent card-lane experiments with a simpler stacked-column layout again: cards now render in centered home/away columns (`width / 4` and `3 * width / 4`) using a compact card font, lower starting Y, and predictable vertical stacking. This is intended to get back to the earlier readable behavior without the center-lane overlap regressions.
- Red cards now use the same entry/list model as yellow cards for numbering and stacking. New timed reds are appended instead of replacing the prior entry, they are labeled `R1`, `R2`, etc., and persistence now stores/restores the red label counters alongside the yellow counters.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (builds passed; existing container-analysis/type warnings remain).

## [2026-04-01] Reserve a protected center lane for the main countdown

- Tightened the sanction-card layout again so card text no longer shares the center lane with the main countdown. Home cards now right-align to the left edge of a protected center zone, away cards left-align to the right edge of that zone, and the compact Fenix targets use the same smaller font for both yellow and red entries.
- Increased the vertical gap between the card stack and the main countdown so active sanctions sit above the clock instead of riding directly on top of it.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (builds passed; existing container-analysis/type warnings remain).

## [2026-04-01] Anchor card timers under the team score columns

- The remaining overlap was horizontal: card timers were still rendered as inward-growing edge labels, so long `Y1 9:49` / `R 19:53` strings could intrude into the center countdown area even after the vertical layout was measured.
- Moved both teams' sanction stacks to the home/away score columns (`width * 0.25` / `width * 0.75`) and center-justified the text there. That keeps yellow/red timers visually associated with the correct team while reserving the middle of the screen for the large countdown.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (builds passed; existing container-analysis/type warnings remain).

## [2026-04-01] Switch the main match screen to measured layout

- Replaced the main-screen percentage-only vertical placement with a measured layout pass that uses actual font heights plus the live card-row count to place the card band, large countdown, state text, and hint lines. This is meant to stop the repeated overlap regressions on round Fenix screens when cards are active or the match is paused.
- Normalized red and yellow card timer text to the same font size and derived the card row spacing from that measured font height so red sanctions no longer render smaller or collide with adjacent card lines.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (builds passed; existing container-analysis/type warnings remain).

## [2026-04-01] Hide card timers during conversion overlays and declutter paused layout

- Conversion and penalty overlays no longer draw the yellow/red card stack. The sanction timers keep running in the model, but the overlay now reserves the screen for the main match countdown, the special timer, and a short bottom control hint instead of layering cards across the conversion view.
- Shifted the main-screen card band upward and tightened its row spacing so active cards consume less vertical space while keeping the large central countdown at full size. Also removed the extra paused-state resume hint line so the pause screen has less bottom-text overlap.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (builds passed; existing container-analysis/type warnings remain).

## [2026-04-01] Restore absolute-time card timer updates

- Root cause: `RugbyTimerTiming.updateGame()` was correctly passing the absolute `System.getTimer()` value into `RugbyTimerCards.updateYellowTimers()`, but the helper had drifted back to treating that third argument as a per-tick delta. That meant live yellow/red card entries were subtracting a huge raw timestamp from `remaining`, which made the timers expire or disappear immediately.
- Fix: changed `RugbyTimerCards.updateYellowTimers()` back to true absolute-time semantics. Live card entries now derive their remaining time from `startTime` and the current `now` value, while paused/frozen entries still use stored `remaining`.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (builds passed; existing container-analysis/type warnings remain).

## [2026-04-01] Fix red card timer type mismatch (Long vs Number) and sentinel refactor

- Root cause: `(Number - Float).toLong()` yields `Lang.Long`; `isNumeric` only checked `Number | Float`, so the first decrement made `redHomePausedRemaining` a Long, which failed the `isNumeric` check and immediately cleared the card to null — renderer showed `R:--` after the first tick.
- Fix 1 (`RugbyTimerTiming.mc`): Changed `.toLong()` → `.toNumber()` on the red card decrement so the value stays `Lang.Number`. Removed the now-dead boolean fallback that would have assigned `redHome = true` (boolean) back into `redHomePausedRemaining`.
- Fix 2 (`RugbyTimerRenderer.mc`): Changed `redHomeActive`/`redAwayActive` detection from `redHome > 0` (broken since `redHome` is now boolean `true`) to `redHome == true`; also added `instanceof Lang.Float` to the `redHomePausedRemaining` active detection for robustness.
- Fix 3 (`RugbyGameModel.mc`): Removed stale `getRedRemaining(redHome, now)` fallback from `pauseGame()` — `redHome` is now `true` (not a timestamp), so this would have computed garbage. `redHomePausedRemaining` is always valid at pause time since `recordRedCard` sets it and the tick loop keeps it current.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` (warnings only, no errors).

## [2026-04-01] Shorten idle guidance and make preset selection deterministic

- Split the idle guidance into short centered safe-area lines instead of one long bottom-bezel sentence. The main idle screen now shows `UP/DOWN set` and `SELECT start`, which avoids the round-screen clipping shown on the Fenix screenshots.
- Changed the preset picker again so it applies the selected profile on a short delayed callback after the picker closes, then explicitly resets the idle countdown and persists the result. This avoids device-specific selection timing issues and should make the chosen 7s/10s/15s/U19 timer visible immediately on the main screen.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (builds passed; existing container-analysis/type warnings remain).

## [2026-04-01] Apply presets after menu close and keep suspensions live through halftime

- Changed the `Match Preset` picker so profile changes are applied after the picker closes instead of during the selection callback. On-device this gives the main view a clean redraw path and forces the idle countdown to update immediately to the selected Rugby 7s / 10s / 15s / U19 preset.
- Fixed the suspension-clock bug in `RugbyTimerTiming.mc`: yellow and timed-red timers are now updated from the current absolute timestamp, not the frame delta. That stops newly added cards from expiring instantly and also allows suspensions to continue through halftime while still freezing correctly on an explicit referee pause.
- Cleaned up the idle screen by removing the redundant `Ready to start` state line and shortening/lifting the bottom instruction text so it no longer clips into the bezel on round Fenix layouts.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (builds passed; existing container-analysis/type warnings remain).

## [2026-04-01] Rebalance the main timer screen layout

- Reworked the main match-screen renderer for round Fenix devices so the base UI reads as a cleaner scoreboard instead of a stack of overlapping labels. Yellow/red card timers now render in left/right side columns, the large countdown is slightly smaller on compact round screens, and the bottom `PAUSED` / resume text now sits in a reserved lower status band.
- Tightened the card stack spacing and shifted the card block upward so active cards stay readable without forcing the main countdown and paused-state labels to collide near the bottom of the display.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (builds passed; existing container-analysis/type warnings remain).

## [2026-03-31] Route in-app configuration to a preset picker and stabilize card sanctions

- Replaced the broken in-app settings route with a direct `Match Preset` picker. A held `UP/MENU` press now opens the preset dialog straight from the main timer screen, and the former crashing main-menu `Settings` item now opens that same lightweight preset menu instead of the old nested settings stack.
- Tightened the conversion-overlay hardware mapping further by removing the raw `KEY_UP` make-conversion shortcut, so `+2` now stays on the Fenix `UP/MENU` path (`onPreviousPage` / `KEY_MENU`) rather than drifting onto the wrong physical button.
- Changed yellow-card timer handling to keep live entries attached to their original start times instead of rebuilding fresh dictionaries on every tick, and forced card-menu selections to request a redraw immediately after the menu closes. This is aimed at the case where a yellow card briefly appeared and then disappeared after selection.
- Updated sanction rules so only a 7-minute sevens setup uses a 2-minute yellow card and permanent red-card dismissal; every other match variant now uses a 10-minute yellow and a 20-minute timed red replacement window. Halftime does not pause those sanctions, so extra elapsed time after the scheduled half end still counts toward the suspension, while an explicit referee pause still freezes the card timers.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (builds passed; existing container-analysis warnings remain, along with the pre-existing `RugbySettings.mc` unreachable-statement warning and the existing container-typing warnings in the card/persistence helpers).

## [2026-03-30] Right-align conversion prompts to the left button column

- Changed the conversion overlay prompts to draw right-justified from the left button column instead of left-justified into the timer area. `+2` now anchors on the middle-left button line and `MISS` on the lower-left button line, keeping both prompts beside the hardware buttons rather than overlapping the large red conversion countdown.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (existing container-analysis warnings remain, along with the pre-existing `RugbySettings.mc` unreachable-statement warning and the paused-yellow-card container-assignment warnings at `RugbyGameModel.mc:717-718`).

## [2026-03-30] Wrap in-app settings in a host view and realign conversion prompts

- In-app settings no longer push `RugbySettingsMenu` directly from the timer or main-menu delegates. They now push a lightweight `RugbySettingsHostView`, which opens the settings menu on its own show cycle and gives the view stack a normal screen transition before `Menu2` appears. The root settings menu also now closes both the menu and host when backing out from an in-app settings session.
- Simplified the root settings menu further by building it once from current values and avoiding runtime `setSubLabel()` mutation afterward. This keeps the settings screen on a more conservative code path for device compatibility.
- Moved the conversion overlay `+2` prompt down to the middle-left `UP/MENU` button line and the `MISS` prompt up to better align with the lower-left `DOWN` button line on Fenix-style hardware.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (existing container-analysis warnings remain, plus the pre-existing unreachable-statement warning in `RugbySettings.mc` and the paused-yellow-card container-assignment warnings at `RugbyGameModel.mc:717-718`).

## [2026-03-30] Remove constructor-time enabled flags from settings menu

- Replaced the `MenuItem(..., {:enabled => ...})` pattern in `RugbySettingsMenu` with plain `MenuItem(..., null)` construction and moved the idle-only enforcement for `Profile`, `Format Family`, and `Half Timer` into the settings delegate. Selecting those rows during a live match now shows an `Idle only` overlay instead of relying on constructor-time item flags.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (existing container-analysis warnings and the pre-existing `RugbySettings.mc` unreachable-statement warning remain; the paused-yellow-card assignment still adds two container-assignment warnings at `RugbyGameModel.mc:717-718`).

## [2026-03-30] Defer settings handoff and pause card clocks with the match

- Changed the in-app `Settings` menu item to close the current menu first and then open `RugbySettingsMenu` on a short delayed timer callback, which avoids the old push/pop collision that could crash on watch when entering settings from the main menu.
- Yellow-card timers now freeze when the referee pauses the match or pauses the clock, then resume from the same remaining time when play restarts. Timed red cards now follow the same pause/resume rule, and the card renderer/persistence paths prefer frozen remaining-time snapshots while paused instead of continuing to age from absolute start times. Cards logged while the match is already paused now start in that same frozen state instead of immediately ticking down.
- Built successfully with `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` and `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` (existing container-analysis warnings and the pre-existing `RugbySettings.mc` unreachable-statement warning remain; the latest build also adds two new container-assignment warnings at `RugbyGameModel.mc:717-718` from freezing paused yellow-card entries).

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

- 2026-04-01: Kept the top count-up clock on `elapsedTime` so it continues running while the match countdown is paused, added a repeating pause-reminder haptic every 15 seconds, and render `PAUSED` in red with a larger font treatment.

- 2026-04-01: Capped visible sanction timers to the first two active yellow/red entries per team while keeping additional cards running hidden in the background; yellow/red displays now use the same rounding path as the main countdown so they stay visually synchronized.

- 2026-04-01 build: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).

- 2026-04-01 build: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).

- 2026-04-01 rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).

- 2026-04-01 rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).

- 2026-04-03: Generalized the one-shot runtime status path so save/input/restore failures can surface on-watch, invalid saved snapshots are now cleared and reset safely instead of partially restoring, and added `scripts/validate-local.sh` as the single local build-validation entrypoint. Added regression coverage in `tests/Test_RugbyRuntimeStatus.mc`.

- 2026-04-03 rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL.

- 2026-04-03 test rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` -> BUILD SUCCESSFUL.

- 2026-04-03 local validation: `./scripts/validate-local.sh` -> BUILD SUCCESSFUL for app target and test target; script now prints the correct simulator command shape: `monkeydo bin/tests.prg 1 -t`.

- 2026-04-03: Fixed the Garmin unit-test workflow so `scripts/run-tests.sh` now compiles with `--unit-test`, added persistence/model transition coverage in `tests/Test_RugbyTimerPersistence.mc`, persisted custom profile labels, disabled the debug profiler by default for smoother runtime behavior, and added `docs/CODEBASE_AUDIT.md` with organization/refactor/performance guidance.

- 2026-04-03 build: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / pre-existing unreachable-statement warnings).

- 2026-04-03 test build: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / pre-existing unreachable-statement warnings).

- 2026-04-03: Added `handoff.md` as the running checkpoint for this effort and completed the first `RugbyGameModel` debt-reduction pass by extracting clock, scoring, discipline, recording, and snapshot orchestration into focused helper services while keeping `RugbyGameModel` as the public facade. Added wrapper-level unit tests to confirm the facade still preserves start/pause/resume, try-to-conversion, undo, and save-summary behavior.

- 2026-04-03 rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / pre-existing unreachable-statement warnings).

- 2026-04-03 test rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / pre-existing unreachable-statement warnings).

- 2026-04-03 runtime test attempt: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeydo" /tmp/rugbytimer-tests.prg /t` -> FAILED in this environment with `Unable to connect to simulator`. Attempting to launch the bundled `connectiq` app also failed, so unit tests are compile-verified but not simulator-executed here.

- 2026-04-03: Added typed wrappers for match profiles and score events (`MatchProfileEntry`, `ScoreEvent`) to reduce raw-dictionary access in the newly touched service/model paths, added unit tests for those wrappers, and documented the remaining naming/overlap hotspots in `handoff.md` and `docs/CODEBASE_AUDIT.md`.

- 2026-04-03 warning-reduction rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warning set reduced in the touched profile/scoring paths; remaining warnings are still concentrated in older dictionary-heavy modules and pre-existing unreachable branches).

- 2026-04-03 warning-reduction test rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` -> BUILD SUCCESSFUL (same caveat: compile-verified only; simulator execution still unavailable in this environment).

- 2026-04-03: Added `EventLogEntry` and `RugbySettingsSupport` to pull pure event-log/settings parsing away from the larger UI files, and added direct unit coverage for the new helper layer (`Test_RugbyEventLogEntry`, expanded `Test_RugbyTypedEntries`, expanded `Test_RugbySettings_UI`).

- 2026-04-03 warning-reduction rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings reduced again; newly touched settings/profile/event-log paths are clean, remaining warnings are concentrated in older persistence/renderer/timing code plus the intentionally disabled profiler path).

- 2026-04-03 warning-reduction test rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` -> BUILD SUCCESSFUL (compile-verified only; simulator execution is still blocked by the local `monkeydo` connection failure).

- 2026-04-03: Split `RugbySettings` into focused modules (`RugbySettingsMenu`, `RugbySettingsNavigation`, `RugbySettingsPickers`) and moved the menu/dialog classes out of `RugbyTimerDelegate` into `RugbyTimerMenus` so the remaining delegate file is centered on hardware input behavior.

- 2026-04-03 structural cleanup rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (same remaining warnings: older persistence/renderer/timing modules, one low-risk card-label parsing warning, and the intentionally disabled profiler branch).

- 2026-04-03 structural cleanup test rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` -> BUILD SUCCESSFUL (compile-verified only; simulator execution is still blocked by the local `monkeydo` connection failure).

- 2026-04-03: Added concise maintainability documentation to the newly extracted settings/menu modules and the typed wrapper/helper files so each module now documents its responsibility boundary and any non-obvious compatibility behavior.

- 2026-04-03 documentation-pass rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (same remaining warnings: older persistence/renderer/timing modules, one low-risk card-label parsing warning, and the intentionally disabled profiler branch).

- 2026-04-03 documentation-pass test rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` -> BUILD SUCCESSFUL (compile-verified only; simulator execution is still blocked by the local `monkeydo` connection failure).

- 2026-04-03: Extracted pure `RugbyTimerDelegate` rules into `RugbyTimerInputSupport` and added direct unit coverage for idle-minute adjustment, overlay key routing, and hold-to-preset gating.

- 2026-04-03 delegate-helper rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (same remaining warnings: older persistence/renderer/timing modules, one low-risk card-label parsing warning, and the intentionally disabled profiler branch).

- 2026-04-03 delegate-helper test rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` -> BUILD SUCCESSFUL (compile-verified only; simulator execution is still blocked by the local `monkeydo` connection failure).

- 2026-04-03: Added typed adapters for persisted snapshots, serialized sanction timers, timer-update results, and renderer layout/font/card-info values (`PersistedGameSnapshot`, `PersistedCardTimerEntry`, `PersistedStatePair`, `RugbyTimerRenderTypes`) and rewired persistence/render/timing/view code to use them.

- 2026-04-03 persistence-render cleanup rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/rugbytimer-build.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warning set reduced again; remaining production warnings are limited to `Profiler`, a small `RugbyTimerCards` parsing path, and a few renderer cache accesses).

- 2026-04-03 persistence-render cleanup test rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f test_monkey.jungle -o /tmp/rugbytimer-tests.prg -d fenix6 -y /Users/600171959/developer_key -w --unit-test` -> BUILD SUCCESSFUL (compile-verified only; simulator execution is still blocked by the local `monkeydo` connection failure).

- 2026-04-02: Reworked timer architecture so the app now advances three separate clocks: `elapsedTime` for the always-running top count-up, `gameTime` for the pauseable match countdown and special timers, and `suspensionTime` for yellow/red sanctions. Card rendering and persistence now use `suspensionTime` instead of wall-clock timestamps and cached `remaining` values, which is intended to remove the persistent drift after pause/resume and card entry during stoppages.

- 2026-04-02 build: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).

- 2026-04-02 build: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).

- 2026-04-02: Fixed the sanction-clock regression after the timer-architecture split. Yellow/red cards were already moved onto `suspensionTime`, but the live remaining-time helper was still dividing by `1000` as if those values were wall-clock milliseconds. Card timers now use the same second units as `gameTime`/`suspensionTime`, so they activate and tick from the shared synchronized update pass again.

- 2026-04-02 rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).

- 2026-04-02 rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).

- 2026-04-01: Recording a yellow or red card now forces the match into the paused state first, and newly created sanction timers inherit the main countdown clock phase so their displayed second changes stay aligned with the main countdown when play resumes.

- 2026-04-01: Shortened the paused reminder haptic cadence from every 15 seconds to every 5 seconds.

- 2026-04-01 rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).

- 2026-04-01 rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).

- 2026-04-01: Switched live yellow/red sanction countdowns from integer-second truncation to float-second elapsed time so card timers roll over in sync with the main match countdown instead of lagging by a partial second.

- 2026-04-01 rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o bin/garminrugbytimer.prg -d fenix6 -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).

- 2026-04-01 rebuild: `"/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeyc" -f monkey.jungle -o /tmp/garminrugbytimer-fenix7x.prg -d fenix7x -y /Users/600171959/developer_key -w` -> BUILD SUCCESSFUL (warnings only: existing container-analysis warnings / unreachable-statement warnings).
