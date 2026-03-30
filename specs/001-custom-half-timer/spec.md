# Reconciliation: 001-custom-half-timer ← 002-custom-half-timer

## Context

- The repository contains a complete feature spec and implementation plan under `specs/002-custom-half-timer/` implementing a fully customizable half timer (per-type persistence, free-minute picker, Settings integration).
- The `specs/001-custom-half-timer/` directory had no `spec.md` present. This file records the reconciliation so `001` is no longer an orphan.

## Decision

- Source of truth: `specs/002-custom-half-timer/spec.md` (copied/expanded into branch 002). Treat `002` as authoritative; `001` is therefore reconciled by adopting `002` and recording gaps below.
- Action taken: created this reconciliation note and a short coverage map of underspecified areas (see below). If you prefer, I can also copy `002` verbatim into `001/spec.md` and mark `002` as the canonical spec.

## Coverage summary (taxonomy)

- Functional Scope & Behavior: Clear
  - Core user goals, flows for new-game picker, settings, and persistence are well defined.

- Domain & Data Model: Partial
  - Storage keys and read/write priority are defined (`halfDuration7s`, `halfDuration15s`, legacy `countdownTimer`, `rugby7s`) but the exact naming for "lastGameType" is ambiguous (spec uses `lastGameType` in requirement text, code uses `rugby7s`).

- Interaction & UX Flow: Partial
  - Picker flow, Settings disabling during matches, and acceptance scenarios are specified. Missing: first-run prompts, onboarding for GPS consent, and explicit error UI for storage corruption.

- Non-Functional Quality Attributes: Missing/Partial
  - No measurable performance/latency/battery impact targets. Save frequency is implemented (5s) in code but not justified in spec.

- Reliability & Observability: Missing
  - No explicit requirements for handling Storage failures, corruption, or recovery steps; logging/metrics expectations absent.

- Security & Privacy: Missing
  - GPS recording is described (start/stop) but the privacy/consent model (opt-in, prompt, export behavior of GPS data in event logs) is not specified.

- Integration & External Dependencies: Partial
  - Build and CI instructions exist, but the spec doesn't lock SDK versions or expected CI secrets handling beyond a note in AGENTS.md.

- Edge Cases & Failure Handling: Partial
  - Some edge cases listed (00 clamp, corrupted/missing stored values). Concurrency/conflict scenarios (e.g., simultaneous writes) not addressed.

- Constraints & Tradeoffs: Partial
  - Device support and layout constraints are documented; tradeoffs (e.g., not supporting sub-minute durations) are explicit.

- Terminology & Consistency: Partial
  - Most terms are canonical, but `lastGameType` vs `rugby7s` naming inconsistency should be reconciled.

- Completion Signals / Acceptance Criteria: Clear
  - SC-001..SC-005 provide testable outcomes.

## Underspecified / Actionable gaps (high impact)

1. GPS privacy & consent model — whether recording must be explicit opt-in, default-on, or prompt-on-first-use; and whether GPS data is included in event log exports.
2. Storage error handling — expected behavior when `Storage.setValue` fails or stored data appears corrupted (user-facing error, fallback, or silent recovery?).
3. First-run onboarding behavior — whether to prompt about defaults (game type, GPS opt-in) and how `rugby7s`/`lastGameType` should be set initially.
4. Localization / Accessibility — supported languages (manifest currently lists `eng` only) and accessibility behaviors (contrast, vibration intensity per device) are not specified.
5. Observability & CI pinning — CI SDK version pinning and build reproducibility requirements (currently referenced in docs but not locked in spec), and what logs/telemetry to emit for debugging.

## Suggested next actions

- Confirm GPS privacy/consent approach (high priority). If you want, I can prepare the wording & UI flow for a first-use prompt and the Settings toggle.
- Decide on storage key canonicalization: keep `rugby7s` (existing code) and update spec text to use that key name, or add `lastGameType` as an explicit alias and migrate.
- Specify Storage failure policy (e.g., retry/backoff, user-visible "Restore Defaults" path, and whether builds should include a debug log option).

---

*Created by agent on 2026-03-25 — reconciliation of `001` to `002`.*
