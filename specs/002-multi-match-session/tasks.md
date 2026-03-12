# Tasks: Multi-Match Session Mode

**Input**: Design documents from `/specs/002-multi-match-session/`
**Prerequisites**: plan.md ✅ · spec.md ✅ · research.md ✅ · data-model.md ✅ · quickstart.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelisable — different files, no dependency on an incomplete sibling task
- **[Story]**: User story label (US1 / US2 / US3) — only in user-story phases
- Exact file paths are included in every description

---

## Phase 1: Setup

**Purpose**: Add the `Toybox.Time` import and the `matchStartWallClock` field that all subsequent work depends on.

- [X] T001 Add `using Toybox.Time;` import and declare `var matchStartWallClock;` field in `source/RugbyGameModel.mc`

**Checkpoint**: `RugbyGameModel` compiles with new field — build must pass before Phase 2.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Session log persistence helpers and model orchestration method. Nothing in Phases 3–5 can be built without these.

**⚠️ CRITICAL**: No user-story work can begin until this phase is complete.

- [X] T002 [P] Add `loadSessionLog()`, `loadSessionMatchCount()`, `appendSessionEntry()`, and `clearSession()` static helpers to `source/RugbyTimerPersistence.mc` using Storage keys `"sessionLog"` (Array\<Dictionary\>, max 20 entries, silent oldest-drop) and `"sessionMatchCount"` (Number, starts at 1)
- [X] T003 [P] Set `matchStartWallClock = Time.now().value()` in `startGame()` and clear to `null` in `resetGame()` in `source/RugbyGameModel.mc`
- [X] T004 Add `nextMatch()` method to `source/RugbyGameModel.mc`: builds a `MatchRecord` dict (matchNum from `loadSessionMatchCount`, gameType label derived from `is7s ? "7s" : "15s"` with a `// TODO(001): update to 3-way mapping when 001-custom-half-timer is merged` comment, homeScore, awayScore, startTimeSec from `matchStartWallClock`), calls `appendSessionEntry()`, then calls `resetGame()` — depends on T002, T003

**Checkpoint**: `model.nextMatch()` can be called from the REPL; session log entry persists across simulated app restart.

---

## Phase 3: User Story 1 — Automatic Reset and Session Log After Each Match (P1) 🎯 MVP

**Goal**: After a match ends, the referee can select "Next Match" from an end-game menu, which saves the final scoreline to the session log and resets the app to STATE_IDLE (1st Half, 0–0).

**Independent Test**: Play two full matches back-to-back using the "Next Match" prompt. After the second match, open the session log (US2 not needed — call `RugbyTimerPersistence.loadSessionLog()` via Storage inspector or log a `System.println`) and confirm both entries are present with correct match numbers, game types, and scores.

- [X] T005 [P] [US1] Add `EndGameMenu` class to `source/RugbyTimerDelegate.mc`: a `WatchUi.Menu2` with 4 items — `:next_match` ("Next Match"), `:view_session_log` ("Session Log"), `:reset` ("Reset"), `:exit` ("Exit")
- [X] T006 [P] [US1] Add `<menu-item id="view_session_log" label="Session Log" />` to the existing `MainMenu` block in `resources/menus/menu.xml`; `EndGameMenu` implemented programmatically (class-based, consistent with other menus in this codebase)
- [X] T007 [US1] Add `EndGameDelegate` class to `source/RugbyTimerDelegate.mc`: handles `:next_match` → `model.nextMatch(); WatchUi.popView(SLIDE_DOWN)`, `:reset` → `model.resetGame(); WatchUi.popView(SLIDE_DOWN)`, `:exit` → `model.stopRecording(); System.exit()`; `:view_session_log` handler left as stub (wired in Phase 4) — depends on T004, T005
- [X] T008 [US1] Hook SELECT press in `STATE_ENDED` on the main watch-face input delegate in `source/RugbyTimerDelegate.mc`: when `model.gameState == STATE_ENDED`, push `EndGameMenu` / `EndGameDelegate` via `WatchUi.pushView(..., WatchUi.SLIDE_UP)` — depends on T005, T007
- [X] T009 [P] [US1] Add string IDs `EndGame_NextMatch`, `EndGame_SessionLog`, `EndGame_Reset`, `EndGame_Exit` to `resources/strings/strings.xml`

**Checkpoint**: Start a match → End Game → Confirm "GAME ENDED" on watch face → SELECT → `EndGameMenu` appears → "Next Match" resets scores to 0–0, half to 1, enters STATE_IDLE.

---

## Phase 4: User Story 2 — View and Navigate Session Log (P2)

**Goal**: The referee can open the session log from the main menu at any time to see all completed matches in the current session as a scrollable list.

**Independent Test**: Play 3 matches, then open the Session Log from the main menu mid-fourth match. Confirm the 3 completed matches are listed with correct scores, game types, and start timestamps.

- [X] T010 [P] [US2] Add `SessionLogMenu` class to `source/RugbyTimerDelegate.mc`: a `WatchUi.Menu2` built from `RugbyTimerPersistence.loadSessionLog()`; each entry becomes a `WatchUi.MenuItem` with label `"M{n} ({type}): {h} – {a}"` and subtitle formatted as `HH:MM` from `startTimeSec`; if log is empty, show a single disabled item "No matches yet"
- [X] T011 [P] [US2] Add `SessionLogDelegate` class to `source/RugbyTimerDelegate.mc`: a `WatchUi.Menu2InputDelegate`; `onBack()` pops the view; no item selection required (read-only list)
- [X] T012 [US2] Handle `:view_session_log` in the existing main-menu delegate (`MainMenuDelegate.onSelect()`) in `source/RugbyTimerDelegate.mc`: push `SessionLogMenu` / `SessionLogDelegate` — depends on T010, T011
- [X] T013 [US2] Wire `:view_session_log` inside `EndGameDelegate.onSelect()` in `source/RugbyTimerDelegate.mc` (replaces the stub left in T007): push `SessionLogMenu` / `SessionLogDelegate` — depends on T010, T011, T007
- [X] T014 [P] [US2] Add string IDs `Session_NoMatches` to `resources/strings/strings.xml`

**Checkpoint**: Open main menu → "Session Log" → scrollable list of all completed matches shown; "No matches yet" displayed when log is empty; back button returns to previous screen.

---

## Phase 5: User Story 3 — Configure and Reset Session (P3)

**Goal**: The referee can clear the session log and reset the match counter to M1 via Settings → Clear Session.

**Independent Test**: Play 2 matches, clear the session via Settings → "Clear Session" → confirm. Play another match and confirm it is logged as M1.

- [X] T015 [P] [US3] Add `clear_session` menu item ("Clear Session") to `RugbySettingsMenu.initialize()` in `source/RugbySettings.mc` (menu is programmatic, not XML-based)
- [X] T016 [US3] Handle `:clear_session` in `RugbySettingsMenuDelegate.onSelect()` in `source/RugbySettings.mc`: call `RugbyTimerPersistence.clearSession()` then pop the view
- [X] T017 [P] [US3] Add string ID `Settings_ClearSession` to `resources/strings/strings.xml`

**Checkpoint**: Settings → "Clear Session" → session log empty and match counter reset to 1; next completed match is logged as M1.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T002 Build with `monkeybrains.jar -d fenix6_sim` (zero errors required) and record the build command, target, and PASS/FAIL in `log.md`
- [ ] T019 [P] Execute the manual test checklist from `specs/002-multi-match-session/quickstart.md` and record results in `log.md`; include an explicit GPS check: end a match, open `EndGameMenu`, and confirm `model.session == null` (GPS already stopped by `endGame()` before the menu is shown) — satisfies FR-008
- [X] T020 [P] Update `project_technical_document.md` with session log architecture

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup
    └─► Phase 2: Foundational (T001 must be done first)
            └─► Phase 3: US1 (T002-T004 must be done)
                    └─► Phase 4: US2 (T005-T009 must be done)
                            └─► Phase 5: US3 (independent of US1/US2 except T002)
                                    └─► Phase 6: Polish (all phases done)
```

### User Story Dependencies

- **US1 (P1)**: Depends on Foundational complete — no dependency on US2 or US3
- **US2 (P2)**: Depends on US1 complete (UI entry points from `EndGameDelegate`) — independently testable via main-menu path
- **US3 (P3)**: Depends on Foundational only (calls `clearSession()`) — can be implemented alongside US1

### Within-Phase Parallel Opportunities

| Phase | Parallelisable Tasks | Constraint |
|-------|---------------------|------------|
| Phase 2 | T002 + T003 | Different files; T004 waits for both |
| Phase 3 | T005, T006, T009 | All in different files; T007 waits for T005; T008 waits for T007 |
| Phase 4 | T010, T011, T014 | T012, T013 wait for T010+T011 |
| Phase 5 | T015, T017 | T016 waits for T015 (or can be in same edit) |
| Phase 6 | T019, T020 | Both wait for T002 (build must pass first) |

---

## Implementation Strategy

**MVP scope (Phase 3 only — US1)**: Completing T001–T009 delivers the complete core value: tournament referee can chain matches back-to-back with a persistent score log. US2 and US3 are enhancements built on top.

**Suggested sequence for a single developer**:
1. T001 → T002 + T003 in parallel → T004 (foundation, ~30 min)
2. T005 + T006 + T009 in parallel → T007 → T008 (US1 UI, ~45 min)
3. T010 + T011 → T012 + T013 + T014 in parallel (US2 view, ~30 min)
4. T015 + T017 → T016 (US3 clear, ~10 min)
5. T002 → T019 + T020 in parallel (build + verify, ~20 min)

**Total task count**: 20 tasks across 6 phases
- Phase 1: 1 task
- Phase 2: 3 tasks (US0 — Foundational)
- Phase 3: 5 tasks (US1)
- Phase 4: 5 tasks (US2)
- Phase 5: 3 tasks (US3)
- Phase 6: 3 tasks (Polish)
