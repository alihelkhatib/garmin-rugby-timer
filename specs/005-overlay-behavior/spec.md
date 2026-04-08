# Feature Spec: Overlay Behavior & Contracts

## Context
Specify rendering, stacking, and lifecycle rules for overlays (conversion, penalty, menus) and their interactions with the main countdown and layout contract.

## Preconditions
- Renderer contracts from docs/UI_SPEC.md are the canonical layout rules.
- Tests should mock view/layout size families (compact_round, large_round, rectangular).

## Key behaviors
- Overlays must keep the main countdown visible near the top; overlays may emphasize a secondary timer/message below the countdown.
- Opening an overlay must not alter the measured countdown anchor unless card-row count changes require it.
- Only one overlay is active at a time. If the model enters an overlay state while another overlay is present, the new state is queued and shown after the current overlay closes.
- If the overlay is dismissed and the model still indicates the overlay state, the overlay should re-open immediately.

## Acceptance scenarios
1) Conversion overlay anchors
- Given main screen is playing
- When conversion overlay opens
- Then the main countdown remains visible and anchoring rules from docs/UI_SPEC.md hold

2) Overlay stacking/queueing
- Given overlay A is visible and model switches to overlay B
- When user closes A
- Then B appears immediately (no lost state)

3) Overlay dismissal vs model state
- Given model still in conversion state after user closes overlay
- Then the overlay reopens (overlay reflects canonical model state)

## Mocks & instrumentation
- Mock model states (STATE_CONVERSION, STATE_PENALTY), and assert renderer draws overlay without changing countdown Y except when card rows change.

## Files referenced
- source/RugbyTimerOverlay.mc
- source/RugbyTimerView.mc
- docs/UI_SPEC.md
