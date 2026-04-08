# Proposal: specs-ambiguities-and-gaps

Summary

This change captures ambiguities discovered while reviewing the newly added specs (003–011) and lists missing feature specs that should be authored next. It collects decisions needed, recommended defaults, and an implementation task list.

Scope

- Audit of specs: specs/003–011 and existing UI/persistence docs
- Produce recommended decisions for ambiguous areas
- Propose the next missing specs to author

Ambiguities found (high-impact)

- Scoring point values are not explicitly specified (try/conversion/penalty/drop-goal/penalty-try).
- Card durations per format (7s vs 15s) are unspecified.
- Conversion overlay countdown default duration is unspecified.
- Export timestamp format and gps-point timestamp format are not normalized (ISO vs epoch).
- Persistence failure handling lacks retry/backoff and atomic-write details (spec asks for silent fallback but not the retry policy).
- Overlay priority/stacking semantics (which overlays preempt others) need precise rules.
- Haptics pattern durations/types are described qualitatively but not numerically (short vs long pulse lengths).

Missing specs (recommended next authors)

- 012-localization-accessibility: localization targets, string fallback, contrast/vibration accessibility rules.
- 013-ci-release-test-plan: SDK pinning, CI jobs, build/release flows, artifact publishing.
- 014-telemetry-observability: error logging, debug modes, internal-only diagnostics.
- 015-performance-and-memory: render timing budgets, allocation rules, profiler guidance.
- 016-permissions-data-protection: data retention, export deletion, privacy compliance beyond GPS.
- 017-screenshot-golden-regression-tests: guidelines for screenshot tests and device coverage.

Recommended next steps

1. Confirm the small decision set below (scoring points, card durations, conversion timeout, export timestamp format, haptics durations) so specs can be finalized.
2. Author the missing specs listed above (I can create them if you want).
3. Update the new specs with the chosen canonical values and add unit/headless tests for persistence, snapshot recovery, overlays, and export formatting.

Artifacts created

- openspec/changes/specs-ambiguities-and-gaps/proposal.md  (this file)
- openspec/changes/specs-ambiguities-and-gaps/design.md
- openspec/changes/specs-ambiguities-and-gaps/tasks.md

Questions for you to confirm before implementation

- Use standard rugby scoring (try=5, conversion=2, penalty/drop goal=3, penalty try=7)?
- Card durations: Yellow=2 min for 7s / 10 min for 15s? Red=PERM?
- Conversion countdown: default 60 seconds and configurable via settings?
- Export timestamps: use ISO8601 for `recordedAt` and GPS point timestamps?
- Haptics durations: short=50ms, long=300ms (per-device may map differently)?

If you approve these defaults I will (optionally) create the missing spec stubs and the implementation task list.
