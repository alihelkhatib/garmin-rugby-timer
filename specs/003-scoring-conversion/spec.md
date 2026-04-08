# Feature Spec: Scoring & Conversion Flow

## Context
Formalize scoring flows (tries, penalty tries, drop goals) and the conversion overlay that follows a try. This spec documents UI/behavior, persistence payloads, and testable acceptance criteria.

## Preconditions
- App on main timer screen (idle or playing).
- Tests should mock Storage.getValue/Storage.setValue and `RugbyGameModel` methods that apply score events.

## Key behaviors
- Recording a Try auto-opens the conversion overlay and pauses the main countdown.
- Conversion overlay accepts a `made` / `missed` decision. `made` applies the conversion score and updates score history; `missed` does not change score.
- Penalty Try and Drop Goal apply immediately without opening the conversion overlay.
- All score-related events persist as normalized dictionaries in `lastEvents`/`scoreHistory` using plain serializable types.

## Acceptance scenarios
1) Record Try → Auto-open conversion
- Given match is playing
- When user records a Try for HOME
- Then conversion overlay opens, main countdown pauses, and a `try` event is appended to `lastEvents` (normalized payload)

2) Conversion made
- Given conversion overlay is open
- When user confirms `made`
- Then HOME score increments by conversion value, an event `{ "type": "conversion", "isHome": true, "result": "made" }` is appended, and Storage.setValue is scheduled (debounced)

3) Conversion missed
- Given conversion overlay is open
- When user confirms `missed`
- Then no score change, event `{ "type": "conversion", "isHome": true, "result": "missed" }` appended, and main countdown resumes

4) Penalty try / drop goal
- Given match is playing
- When user records a Penalty Try or Drop Goal
- Then appropriate score applied immediately and no conversion overlay opens

## Mocks & instrumentation
- Mock `RugbyGameModel` score-apply methods and inspect resulting state.
- Mock Storage to assert debounced write timing and persisted payload shape.
- Simulate timer pause/resume to assert overlay pauses the main countdown.

## Files referenced
- source/RugbyTimerView.mc (score menu, overlay triggers)
- source/RugbyTimerOverlay.mc (overlay UI and result handling)
- source/RugbyScoringService.mc (payload shaping)
