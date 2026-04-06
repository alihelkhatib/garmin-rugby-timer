<!--
SYNC IMPACT REPORT
==================
Version change: (template / 0.0.0) → 1.0.0
Bump type: MINOR — initial constitution authoring from template; all five principles defined for the first time.

Modified principles:
  - [PRINCIPLE_1_NAME] → I. Module Separation (new)
  - [PRINCIPLE_2_NAME] → II. Build-First Release Gate (new)
  - [PRINCIPLE_3_NAME] → III. Manual Verification Before Release (new)
  - [PRINCIPLE_4_NAME] → IV. Documentation Discipline (new)
  - [PRINCIPLE_5_NAME] → V. Coding Convention Compliance (new)

Added sections: Architecture Constraints, Development Workflow
Removed sections: none

Templates requiring updates:
  ✅ .specify/templates/plan-template.md — Constitution Check section is generic; no project-specific changes needed.
  ✅ .specify/templates/spec-template.md — No constitution-specific hooks; template remains valid as-is.
  ✅ .specify/templates/tasks-template.md — Phase/task categorization aligns with defined principles; no changes needed.

Deferred TODOs: none
-->

# Rugby Timer Constitution

## Core Principles

### I. Module Separation

Each source module MUST have a single, clearly defined responsibility:

- `RugbyTimerView.mc` — game state orchestration only; no drawing code.
- `RugbyTimerRenderer.mc` — all layout math and drawing; no state mutations.
- `RugbyTimerTiming.mc` — countdown/game timer logic and haptics; no UI rendering.
- `RugbyTimerCards.mc` — yellow/red card timer dictionaries; no overlay rendering.
- `RugbyTimerOverlay.mc` — overlay screen rendering and interaction; no scoring state.
- `RugbyTimerPersistence.mc` — save/restore and export; no gameplay logic.
- `RugbyTimerEventLog.mc` — event formatting and log view; no scoring state.

New source files MUST be justified by a distinct responsibility that cannot cleanly belong to an existing module. Cross-module calls MUST flow through well-defined method boundaries — no module may directly mutate another module's fields.

**Rationale**: Garmin Connect IQ has strict memory constraints. Keeping modules focused reduces coupling, makes manual testing tractable, and prevents layout/timer regressions from cascading across the codebase.

### II. Build-First Release Gate

No change is considered complete until the Monkey C compiler produces a valid `.prg` artifact with zero errors. Specifically:

- The `monkeybrains.jar` build MUST be run after every source change before committing.
- Build command and device target (`-d fenix6_sim` or hardware) MUST be recorded in `log.md`.
- A change that breaks the build MUST NOT be committed; fix the build first.

**Rationale**: Monkey C is a statically compiled language with no hot-reload. A broken build cannot be caught by linting alone. The build step is the primary correctness gate in the absence of a unit test framework.

### III. Manual Verification Before Release

Before any release (GitHub release, Connect IQ Store upload, or sharing a `.prg`), the following manual test flows MUST pass:

- Timing flows: countdown pause/resume, conversion/kickoff/penalty overlays appear and dismiss correctly.
- Card timer stacking: multiple yellow/red cards per team stack, hidden timers keep ticking, expiry haptics fire.
- Event log export: log entries are timestamped, formatted correctly, and persist to Storage.
- GPS session: `SPORT_RUGBY` recording starts on match start and stops cleanly on game end.
- 10-second yellow-card warning: haptic fires at ≤10 s remaining on any visible yellow card timer.

Results MUST be noted in `log.md` referencing the build entry. There is no configured repository CI workflow; builds and uploads are performed manually using the scripts in `scripts/` unless an automated process is explicitly added and documented. Manual verification remains a required human gate that MUST precede any store upload.

**Rationale**: No automated test harness exists for Connect IQ at this time. Manual verification against the simulator (and hardware where possible) is the only means of protecting against regressions in timing math, layout positioning, and haptic behavior.

### IV. Documentation Discipline

Every change that touches gameplay logic, layout math, timing behavior, persistence, or release configuration MUST include updates to both `log.md` and `project_technical_document.md` in the same commit or PR. Specifically:

- `log.md` MUST record: date, build command invoked, device/simulator target, PASS/FAIL outcome, and any notable observations.
- `project_technical_document.md` MUST be refreshed when architecture, layout math, key behaviors, or persistence details change.
- Commit messages MUST use present-tense imperative style (e.g., `Resize launcher icon`, `Fix card timer stacking`).
- Each logical change MUST be a separate commit; do not batch unrelated changes.
- PR descriptions MUST cite the manual tests executed and link to the relevant `log.md` entry.

**Rationale**: The project has no CI test reports. `log.md` and `project_technical_document.md` are the primary audit trail for correctness and the primary onboarding resource for future contributors.

### V. Coding Convention Compliance

All Monkey C source MUST conform to the following style rules without exception:

- **Indentation**: 4 spaces (no tabs).
- **Classes**: PascalCase (e.g., `RugbyTimerRenderer`).
- **Methods and fields**: camelCase (e.g., `onUpdate`, `countdownTimer`).
- **Constants**: UPPER_CASE (e.g., `MAX_CARD_SLOTS`).
- **Type hints**: MUST NOT use explicit type annotations on local variables (e.g., avoid `var foo as Number`); Monkey C infers local types automatically.
- **Inline comments**: MUST accompany any non-trivial math expression (layout offsets, timer synchronization, card spacing) with a brief `why` explanation, not just a `what`.
- **Launcher icon**: MUST remain 40×40 pixels; do not replace with a different size.

**Rationale**: Consistent style reduces review friction. The no-type-hint rule is idiomatic Monkey C and avoids verbosity that the compiler does not require. Mandatory math comments prevent silent layout regressions when layout constants are adjusted.

## Architecture Constraints

This is an embedded Garmin Connect IQ application, and all design decisions MUST respect the platform's hard constraints:

- **Language**: Monkey C only. No third-party libraries or polyglot modules.
- **SDK**: The pinned SDK version (`connectiq-sdk-win-8.3.0-2025-09-22-5813687a0`) MUST be used for builds. SDK upgrades require an explicit decision, a new build log entry, and a retested `.prg`.
- **Memory**: Wearable devices have kilobytes of RAM. Avoid allocating large collections, deep object graphs, or redundant state copies. Prefer flat dictionaries and primitive arrays.
- **No unit test framework**: Monkey C provides no built-in test runner for Connect IQ watch apps. All correctness verification is manual (Principle III).
- **Resource files**: `resources/drawables/`, `resources/layouts/`, `resources/menus/`, and `resources/strings/` are the only permitted locations for static assets and string tables. Hardcoded UI strings in source MUST be migrated to `strings.xml`.
- **Launcher icon**: MUST be exactly 40×40 px (referenced in `drawables.xml` and `manifest.xml`).
- **Build artifact**: `bin/rugbytimer.prg` is the sole distributable. It MUST be regenerated after every source change.

## Development Workflow

The end-to-end development cycle for any change MUST follow these steps in order:

1. **Plan** — Identify the affected module(s) and verify the change fits within a single module's responsibility (Principle I). If it spans modules, define the interaction boundary first.
2. **Implement** — Write or modify Monkey C source in `source/`. Adhere to coding conventions (Principle V). Add inline comments for any new math.
3. **Build** — Run `monkeybrains.jar` with the standard flags targeting `fenix6_sim`. Record the command in `log.md` (Principle II).
4. **Verify** — Run the applicable manual test flows from Principle III. Record results in `log.md`.
5. **Document** — Update `project_technical_document.md` if architecture, layout, behaviors, or persistence changed (Principle IV).
6. **Commit** — One logical change per commit, present-tense message (Principle IV).
7. **Release** — Tag a GitHub release only after all manual verification passes. There is no configured repository CI workflow to automatically upload artifacts; builds and uploads must be performed manually or through a CI process that is added and documented in the project notes.

## Governance

This constitution supersedes all other practices documented in the repository. When any other document (README, inline comment, prior PR description) conflicts with this constitution, the constitution takes precedence.

**Amendment procedure**:

1. Propose the amendment with a clear rationale explaining what changed and why.
2. Update this file, incrementing `CONSTITUTION_VERSION` per semantic versioning:
   - MAJOR: removal or incompatible redefinition of a principle.
   - MINOR: new principle or section added, or materially expanded guidance.
   - PATCH: clarification, wording fix, or non-semantic refinement.
3. Update `LAST_AMENDED_DATE` to today's date (ISO 8601: YYYY-MM-DD).
4. Propagate changes to any affected templates in `.specify/templates/` and update the Sync Impact Report comment at the top of this file.
5. Commit as: `docs: amend constitution to vX.Y.Z (<brief reason>)`.

**Compliance review**: All PRs that touch `source/`, `resources/`, `monkey.jungle`, or `.github/` MUST be reviewed against this constitution before merge. Complexity violations MUST be explicitly justified in the PR description.

Runtime development guidance is maintained in `AGENTS.md` (project-level) and `project_technical_document.md`.

**Version**: 1.0.0 | **Ratified**: 2025-12-12 | **Last Amended**: 2026-03-10
