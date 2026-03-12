# Research: Haptic Profiles

**Feature**: `011-haptic-profiles`  
**Date**: 2026-03-11  
**Status**: Complete

## Decision 1: Number Allocation Source of Truth

**Question**: Why should the next feature number consider more than local spec folders?

**Decision**: Use the maximum feature number found across both numbered branches (local + remote) and numbered `specs/` directories.

**Rationale**: This avoids collisions when collaborators have already created higher-numbered branches remotely that are not yet represented locally in `specs/`.

**Evidence in current repository**:
- Remote branch `origin/018-multi-match-session` exists.
- Local `specs/` had only `001` and `002` before this feature.
- Next globally safe number is therefore `019`.

## Decision 2: Compliance Scope

**Question**: Which branches are considered compliance candidates?

**Decision**: Only branches matching the numbered feature pattern `###-short-name` are in scope.

**Rationale**: Non-numbered long-lived or operational branches (for example `main` or `feature/...`) are not part of numbered Speckit feature tracking and should not be treated as failures.

## Decision 3: Safe Remediation Strategy

**Question**: How should mismatches be corrected without risking data loss?

**Decision**: Create missing directories/documents; never overwrite existing feature documentation without explicit intent.

**Rationale**: Existing spec artifacts are often hand-curated and may include planning context that must be preserved.

## Decision 4: Required Speckit Document Set

**Question**: What is the minimum complete artifact set for each active feature folder?

**Decision**: Feature folders should include:
- `spec.md`
- `plan.md`
- `research.md`
- `data-model.md`
- `quickstart.md`
- `tasks.md`
- `checklists/requirements.md`

**Rationale**: This matches established structure in prior repository features and supports full specify -> plan -> tasks workflow.