# Feature Roadmap & Prioritization

**Last Updated**: 2026-03-11 | **Total Features**: 2

---

## Priority Order

### 🎯 P1: Feature 001 — Customizable Half Timer

**Status**: Draft (spec complete, plan complete)  
**Branch**: `001-custom-half-timer`  
**Spec**: [specs/001-custom-half-timer/spec.md](specs/001-custom-half-timer/spec.md)

**Rationale**: 
- Foundational feature that enables age-grade and non-standard match durations (U12, U14, U16, etc.)
- Currently blocked by fixed preset list — must be solved first
- All subsequent features leverage the per-game-type duration storage established here
- Feature 002 depends on this being done
- High value unlock for referee user base

**Key Stories**:
- P1: Set custom duration at game start (core blocking feature)
- P2: Adjust duration between matches via settings
- P3: Persist duration across app restarts

**Dependencies**: None (foundation feature)

**Estimated Effort**: Small (3 source modules, 2 storage keys, no new classes)

---

### 🎯 P2: Feature 002 — Multi-Match Session Mode

**Status**: Draft (spec complete, plan complete)  
**Branch**: `002-multi-match-session`  
**Spec**: [specs/003-multi-match-session/spec.md](specs/003-multi-match-session/spec.md)

**Rationale**:
- Enables tournament referees to run 4–8 consecutive matches without manual reset
- Preserves match history (scoreline + timestamp) for post-tournament record-keeping
- Cannot be implemented until Feature 001 ensures timer configuration is flexible
- High value for tournament/pool-stage use cases

**Key Stories**:
- P1: Auto-reset with session log after each match
- P2: View and navigate session log from main menu
- P3: Configure and clear session via settings

**Dependencies**: Feature 001 (requires custom timer config to be established)

**Estimated Effort**: Medium (5 source files, 4 new classes, 2 storage keys, session persistence)

---

## Implementation Sequence

1. **Feature 001** (Customizable Half Timer)
   - Unblocks all subsequent features
   - Foundation for tournament workflows
   - Estimated completion: **Before Feature 002**

2. **Feature 002** (Multi-Match Session)
   - Builds on Feature 001's timer config infrastructure
   - Adds session-level workflows
   - Estimated completion: **After Feature 001 is PASS**

---

## Feature Status Tracking

| # | Feature | Branch | Status | Spec | Plan | Quickstart | Tasks | Build | Tests |
|---|---------|--------|--------|------|------|-----------|-------|-------|-------|
| 001 | Customizable Half Timer | `001-custom-half-timer` | Draft | ✅ | ✅ | ✅ | ✅ | ⏳ | ⏳ |
| 002 | Multi-Match Session | `002-multi-match-session` | Draft | ✅ | ✅ | ✅ | ✅ | ⏳ | ⏳ |

**Legend**:
- ✅ = Complete
- ⏳ = Pending
- ❌ = Blocked

---

## Next Steps

1. **Start Feature 001**: Execute `speckit.implement` for Feature 001 tasks
2. **Build & Test Feature 001**: Run manual test checklist from `001-custom-half-timer/quickstart.md`
3. **Release Feature 001**: Update `project_technical_document.md` and commit to `main`
4. **Start Feature 002**: Only after Feature 001 is PASS and merged

---

## Branching Strategy

All feature work follows this pattern:

- `main` = production releases  
- `001-custom-half-timer` = Feature 001 development  
- `002-multi-match-session` = Feature 002 development (Branch off `main`, not `001-custom-half-timer`)

Each branch is independent until Feature 002 is ready to merge—at which point it will have integrated the latest `main` (which includes Feature 001).
