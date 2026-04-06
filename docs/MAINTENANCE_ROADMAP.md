# Maintenance Roadmap

## Goal

Keep the project stable after the recent cleanup work by focusing on validation,
targeted tests, and release readiness instead of more broad refactoring.

## Next 5 Tasks

1. Strengthen integration coverage for special-timer flows
- Add or extend tests around conversion made/miss handling.
- Add or extend tests around penalty overlay start/hide behavior.
- Add or extend tests around second-half restart and end-game transitions.

2. Keep a lightweight manual regression pass for watch-specific behavior
- Use the checklist in `tests/README.md` before release candidates.
- Prioritize overlay rendering, lock behavior, haptics, GPS recording, and exit/save flows.

3. Do one release-readiness pass on docs and simulator flow
- Confirm `README.md`, `docs/architecture/project_technical_document.md`, and `tests/README.md` still match the actual behavior.
- Run the simulator-backed test path when the local `monkeydo` connection is available.

4. Add small integration tests only where the watch runtime is still risky
- Focus on multi-step user journeys rather than more unit-level helpers.
- Avoid adding test churn unless it protects a real regression-prone flow.

5. Pause large-scale structural refactors unless a feature requires them
- The codebase is in a cleaner state now.
- Prefer feature-driven changes, targeted bug fixes, and validation improvements.

## Nice-To-Haves

- Naming consistency cleanup for a few helper modules if desired later.
- Release checklist automation if simulator/device execution becomes more reliable.
- More device-specific verification notes if Garmin watch behavior differs by family.

## Not Recommended Right Now

- Another broad architecture split.
- More file moves without a strong reason.
- Preemptive performance tuning without a measured device issue.
