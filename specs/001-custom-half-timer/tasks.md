# Tasks: 001-custom-half-timer

**Feature Branch**: `001-custom-half-timer`  
**Generated**: 2026-03-10  
**Plan**: `specs/001-custom-half-timer/plan.md`

---

## Phase 0: Research

- [X] Resolve all NEEDS CLARIFICATION items from spec → `research.md`

## Phase 1: Design

- [X] Define storage schema, entity contracts, method contracts → `data-model.md`
- [X] Write implementation plan with before/after diffs → `plan.md`
- [X] Write manual verification flows → `quickstart.md`

## Phase 2: Implementation

- [X] **Task 1** — `source/RugbyGameModel.mc`: `initialize()` reads per-type key (`halfDuration7s` / `halfDuration15s`) with legacy `countdownTimer` fallback
- [X] **Task 2** — `source/RugbyGameModel.mc`: `setGameType()` loads per-type saved duration instead of overwriting with hardcoded type default
- [X] **Task 3** — `source/RugbyGameModel.mc`: `setHalfDuration()` writes to per-type key instead of generic `countdownTimer`
- [X] **Task 4** — `source/RugbyTimerDelegate.mc`: `GameTypePromptDelegate.onSelect()` pre-fills `MinutesPicker` from per-type storage; added `Toybox.Application.Storage` import
- [X] **Task 5** — `source/RugbySettings.mc`: `RugbySettingsMenu.initialize()` reads per-type key for sub-label; "Half Timer" `MenuItem` disabled while match in progress (`{:enabled => !inGame}`)
- [X] **Task 6** — `source/RugbySettings.mc`: `TimerPickerDelegate.onAccept()` writes to per-type key
- [X] **Task 7** (discovered) — `source/RugbySettings.mc`: `:game_type` toggle writes per-type default instead of `countdownTimer`
- [X] **Task 8** (discovered) — `source/RugbySettings.mc`: `:countdown_timer` picker pre-fill reads per-type key with fallback
- [X] **Task 9** (discovered) — `source/RugbySettings.mc`: `:reset` handler reads per-type key to restore `countdownTimer` on model

## Phase 3: Verification

- [ ] Flow 1 — New-game picker pre-fills from saved value
- [ ] Flow 2 — Custom duration persists across app restart
- [ ] Flow 3 — Settings "Half Timer" disabled during match
- [ ] Flow 4 — Settings "Half Timer" edits current game type only
- [ ] Flow 5 — Zero-minutes clamp to 01

_See `quickstart.md` for step-by-step instructions. Run on `fenix6_sim` after building with `monkeybrains.jar`. Record results in `log.md`._

## Phase 4: Documentation

- [ ] Update `log.md` with build command, target, and PASS/FAIL for each verification flow
- [ ] Update `project_technical_document.md`: add `halfDuration7s` / `halfDuration15s` to storage key table; note `countdownTimer` is now a legacy read-only fallback
