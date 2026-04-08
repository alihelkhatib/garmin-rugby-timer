# Tasks: implement spec clarifications and missing specs

Primary goal: finalize ambiguous decisions, author missing specs, and implement code + tests.

1) Confirm product decisions (blocking)
- Confirm scoring constants, card durations, conversion timeout, export timestamp format, and haptics durations (see proposal.md) — Owner: Product

2) Update specs
- Edit specs/003–011 to include chosen canonical values and add explicit acceptance criteria where ambiguous — Owner: Docs
- Create missing specs (012–017) listed in proposal.md if approved — Owner: Docs

3) Code changes (implementation)
- Add scoring constants and unit tests in `source/RugbyScoringService.mc` — Owner: Dev
- Implement per-format card-duration table in `source/RugbyDisciplineService.mc` and tests in tests/ — Owner: Dev
- Add `conversionTimeoutSeconds` setting and wire overlay countdown in `source/RugbyTimerOverlay.mc` — Owner: Dev
- Implement atomic write + retry in `source/RugbyTimerPersistence.mc` and add Storage-failure unit tests — Owner: Dev
- Add overlay queue/priority logic in `source/RugbyTimerView.mc` and corresponding renderer tests — Owner: Dev
- Add `gpsRecordingEnabled` setting UI and gate recording in `source/RugbyRecordingService.mc` — Owner: Dev
- Implement export schema validation tests (JSON schema) in tests/ — Owner: Dev

4) Tests & QA
- Add unit tests for: scoring, conversion flow, overlay pause/resume, card expiry, persistence failure/recovery, debounced writes consolidation.
- Add headless renderer tests for countdown anchoring with overlays and card rows.
- Manual hardware smoke tests: GPS recording, haptics timing, and on-watch overlays (document in CODEBASE_AUDIT.md).

5) CI / Release
- Pin ConnectIQ SDK version in scripts and CI; add a CI job to run `scripts/validate-local.sh` and unit tests — Owner: DevOps

6) Follow-ups
- Author localization/accessibility spec and performance budgets — Owner: Docs/Dev
- Add screenshot/golden test guidance — Owner: QA

Estimated order: 1 → 2 → 3 → 4 → 5 → 6

Files to change (high level)
- source/RugbyScoringService.mc
- source/RugbyDisciplineService.mc
- source/RugbyTimerOverlay.mc
- source/RugbyTimerView.mc
- source/RugbyTimerPersistence.mc
- source/RugbyRecordingService.mc
- specs/003–011 (update)
- specs/012–017 (create)

Completion signal: all updated specs include explicit numeric/format defaults and CI runs pass unit tests and validate-local build.
