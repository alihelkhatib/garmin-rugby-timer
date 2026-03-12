# Implementation Plan: Multi-Match Session Mode

**Branch**: `002-multi-match-session` | **Date**: 2026-03-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-multi-match-session/spec.md`

## Summary

After a match ends, offer a "Next Match" action that saves the final scoreline (match number, game type, both scores, start timestamp) to a persistent session log — capped at 20 entries — then resets match state to STATE_IDLE while preserving game type and timer settings. The session log is accessible from the main menu at any time and can be cleared via Settings.

**Technical approach**: Add a `matchStartWallClock` field to `RugbyGameModel`; add `appendSessionEntry` / `loadSessionLog` / `clearSession` helpers to `RugbyTimerPersistence`; add `EndGameMenu`, `EndGameDelegate`, `SessionLogMenu`, `SessionLogDelegate` classes to `RugbyTimerDelegate.mc`; hook SELECT in STATE_ENDED on the main watch-face delegate. No new source files required.

## Technical Context

**Language/Version**: Monkey C (Connect IQ SDK 8.3.0-2025-09-22-5813687a0)
**Primary Dependencies**: `Toybox.Application.Storage`, `Toybox.WatchUi`, `Toybox.Time` (new import), `Toybox.ActivityRecording` (existing)
**Storage**: `Application.Storage` flat key-value — new keys `"sessionLog"` (Array\<Dictionary\>) and `"sessionMatchCount"` (Number)
**Testing**: Manual only — no unit test framework available on Connect IQ
**Target Platform**: Garmin Fenix 6 (`fenix6_sim` for simulator builds)
**Project Type**: Embedded watch application (Garmin Connect IQ)
**Performance Goals**: "Next Match" transition completes within 10 seconds of confirmation (SC-001); all session log reads/writes complete within a single frame tick (~100 ms)
**Constraints**: Kilobytes of RAM — session log capped at 20 entries to bound memory; no allocating large intermediate collections; `Array<Dictionary>` serialised atomically via a single `Storage.setValue` call
**Scale/Scope**: 5 source files modified; 2 resource files modified; 4 new classes; 2 new Storage keys

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Module Separation | ✅ PASS | Each new class goes into the correct existing module. Storage helpers in `RugbyTimerPersistence`; UI delegates in `RugbyTimerDelegate`; model orchestration in `RugbyGameModel`. No cross-module field mutation. |
| II. Build-First Release Gate | ✅ PASS | Build must be run after each source change; recorded in `log.md`. |
| III. Manual Verification | ✅ PASS | Manual test checklist defined in `quickstart.md`. |
| IV. Documentation Discipline | ✅ PASS | `log.md` and `project_technical_document.md` updated in same commit. |
| V. Coding Convention Compliance | ✅ PASS | PascalCase classes, camelCase methods, UPPER_CASE constants, 4-space indent, no local type hints. |

### Post-Design Check (Phase 1)

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Module Separation | ✅ PASS | `nextMatch()` in model; persistence helpers in `RugbyTimerPersistence`; all UI in `RugbyTimerDelegate`. No module boundary violations. |
| II–V | ✅ PASS | No changes to prior assessment. |

**No violations. Complexity Tracking table omitted.**

## Project Structure

### Documentation (this feature)

```text
specs/002-multi-match-session/
├── plan.md          ← this file
├── research.md      ← Phase 0 complete
├── data-model.md    ← Phase 1 complete
├── quickstart.md    ← Phase 1 complete
├── spec.md
├── tasks.md         ← Phase 2 (created by /speckit.tasks)
└── checklists/
    └── requirements.md
```

### Source Code (repository root)

```text
source/
├── RugbyGameModel.mc          ← add matchStartWallClock, nextMatch(), Toybox.Time import
├── RugbyTimerPersistence.mc   ← add appendSessionEntry(), loadSessionLog(), clearSession()
├── RugbyTimerDelegate.mc      ← add EndGameMenu, EndGameDelegate, SessionLogMenu, SessionLogDelegate;
│                                  hook STATE_ENDED SELECT; add :clear_session and :view_session_log handlers
├── RugbyTimerView.mc          ← no change
├── RugbyTimerRenderer.mc      ← no change
├── RugbyTimerTiming.mc        ← no change
├── RugbyTimerCards.mc         ← no change
├── RugbyTimerOverlay.mc       ← no change
└── RugbyTimerEventLog.mc      ← no change

resources/
├── menus/menu.xml             ← add EndGameMenu block; add :view_session_log to MainMenu
└── strings/strings.xml        ← add 6 new string IDs
```
