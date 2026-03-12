<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0
Bump type: MINOR — expanded guidance for Release Approval Gate, Build Documentation, Feature Development Workflow, and Session Persistence patterns.

Modified principles:
  - II. Build-First Release Gate — clarified device target and outcome status logging requirements
  - III. Manual Verification Before Release — clarified GitHub Action role vs. human verification gate

Added sections:
  - Feature Development Workflow (subsection of Development Workflow)
  - Session Persistence Patterns (new subsection in Architecture Constraints)
  - Enhanced build documentation logging requirements (Principle II)
  - GitHub Action automation clarification (Principle III)

Removed sections: none

Templates requiring updates:
  ✅ .specify/templates/plan-template.md — Constitution Check section remains generic; no changes needed.
  ✅ .specify/templates/spec-template.md — No new constitution-specific hooks; template remains valid as-is.
  ✅ .specify/templates/tasks-template.md — Phase/task categorization remains aligned; no changes needed.

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
- Build logs in `log.md` MUST record: (a) the full `monkeybrains.jar` command invoked, (b) the device target (`-d fenix6_sim` or hardware model), (c) the build outcome status (PASS or PENDING), and (d) any notable observations.
- A change that breaks the build MUST NOT be committed; fix the build first.
- If a build entry in `log.md` shows PENDING status, the build MUST be completed and re-logged with PASS status before release.

**Rationale**: Monkey C is a statically compiled language with no hot-reload. A broken build cannot be caught by linting alone. The build step is the primary correctness gate in the absence of a unit test framework. Detailed build logs create an audit trail for reproducibility and exception handling.

### III. Manual Verification Before Release

Before any release (GitHub release, Connect IQ Store upload, or sharing a `.prg`), the following manual test flows MUST pass:

- Timing flows: countdown pause/resume, conversion/kickoff/penalty overlays appear and dismiss correctly.
- Card timer stacking: multiple yellow/red cards per team stack, hidden timers keep ticking, expiry haptics fire.
- Event log export: log entries are timestamped, formatted correctly, and persist to Storage.
- GPS session: `SPORT_RUGBY` recording starts on match start and stops cleanly on game end.
- 10-second yellow-card warning: haptic fires at ≤10 s remaining on any visible yellow card timer.

**Human Verification Gate vs. Automation Role**: The GitHub Action (`build_and_publish.yml`) handles automated build and PRG generation; however, it does NOT execute the manual test flows above—those are performed by a human reviewer who MUST verify test results locally in the simulator (and hardware where available) before signing off in the PR or triggering a Connect IQ Store upload. The GitHub Action's role is reproducible build artifact creation; the human reviewer's role is behavioral correctness approval.

Results MUST be noted in `log.md` referencing the build entry.

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

## Session Persistence Patterns

The project supports multi-match session tracking (Feature 002) via the following approved Storage keys and patterns:

- **`sessionLog`** (Array, max 20 entries): Stores completed match records as dictionaries with keys: `matchNum`, `gameType`, `homeScore`, `awayScore`, `startTimeSec`. Managed by `RugbyTimerPersistence.appendSessionEntry()`, `loadSessionLog()`, and `clearSession()`.
- **`sessionMatchCount`** (Number, starts at 1): Monotonic match counter incremented on each match completion. Managed alongside `sessionLog` for session isolation.

These keys are implementation details of Feature 002 and MUST NOT be accessed directly outside `RugbyTimerPersistence.mc`. New session-persistence features MUST extend this pattern rather than introduce duplicate Storage keys. For future features requiring session state:

1. Add new Storage keys with explicit names (e.g., `sessionData_###` = feature number) to avoid collisions.
2. Document the key structure (type, max size, write conditions) in this section and in `project_technical_document.md`.
3. Add accessor methods to `RugbyTimerPersistence.mc` rather than scattering Storage calls across the codebase.

**Rationale**: Wearable devices have limited persistent storage. Centralizing session-persistence accessors prevents key collisions and simplifies crash recovery.

## Development Workflow

### Standard Change Cycle

The end-to-end development cycle for any change MUST follow these steps in order:

1. **Plan** — Identify the affected module(s) and verify the change fits within a single module's responsibility (Principle I). If it spans modules, define the interaction boundary first.
2. **Implement** — Write or modify Monkey C source in `source/`. Adhere to coding conventions (Principle V). Add inline comments for any new math.
3. **Build** — Run `monkeybrains.jar` with the standard flags targeting `fenix6_sim`. Record the command, device target, and PASS/PENDING outcome in `log.md` (Principle II).
4. **Verify** — Run the applicable manual test flows from Principle III. Record results in `log.md`.
5. **Document** — Update `project_technical_document.md` if architecture, layout, behaviors, or persistence changed (Principle IV).
6. **Commit** — One logical change per commit, present-tense message (Principle IV).
7. **Release** — Tag a GitHub release only after all manual verification passes. The GitHub Action uploads to the Connect IQ Store when `CONNECTIQ_STORE_TOKEN` is set.

### Feature Development Workflow

Multi-phase features (e.g., Feature 002 — Multi-Match Session) follow an extended planning and task-sequencing process outlined in `/specs/###-feature-name/` directories. Each feature MUST include:

- **`spec.md`**: User scenarios, requirements, and acceptance criteria (mandatory).
- **`plan.md`**: Technical design, architecture decisions, and implementation strategy (generated by `speckit.plan` after spec).
- **`data-model.md`**: Entity definitions and Storage schema (if applicable).
- **`research.md`**: Investigation of constraints and technical feasibility.
- **`quickstart.md`**: Step-by-step manual test procedure for the feature (mandatory before feature goes to QA).
- **`tasks.md`**: Granular, dependency-ordered implementation tasks (generated by `speckit.tasks` from plan and spec).
- **`checklists/requirements.md`**: Feature approval checklist referencing the requirements in `spec.md`.

Feature development MUST adhere to all Development Workflow steps (Plan–Implement–Build–Verify–Document–Commit–Release) for EACH TASK in `tasks.md`. A feature is only "complete" when all tasks are PASS and the `quickstart.md` test flows succeed end-to-end in the simulator (or hardware if available).

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

**Version**: 1.1.0 | **Ratified**: 2025-12-12 | **Last Amended**: 2026-03-11
