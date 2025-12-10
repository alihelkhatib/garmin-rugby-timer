# Session Log

## [2025-12-11] Score Spacing Fix
- Lowered the tries indicators in `source/RugbyTimerView.mc` so they no longer overlap the main score digits on the Fenix 6 layout.

## [2025-12-12] Try Placement Refinement
- Shifted `triesY` to `height * 0.36` in `source/RugbyTimerView.mc` to add more breathing room under the scores and keep the try text clear of the digits.
- Updated `triesY` to sit just below the half indicator and switched to a centered `homeT/awayT` string so the try info lives between the scores without duplicating text on each side.

## [2025-12-13] Revert card/main timer layout
- Rolled the card timer / main timer layout back to the pre-layout-refactor implementation so the spacing resembles the earlier stable state, only keeping the centered `homeT / awayT` text beneath the half indicator.

## [2025-12-14] Swap timer roles
- Flipped the main/secondary timer text so the countdown timer now occupies the primary (white) position while the game clock moves to the lower slot with the dim/red accent color.

## [2025-12-15] Keep gameTimer running when countdown pauses
- Adjusted `updateGame` so `gameTime` keeps counting even while countdown actions are suspended (e.g., paused), while `countdownRemaining` only ticks during active phases.

## [2025-12-16] Cap card timers & yellow warning
- Display-only the first two yellow timers per side so extras keep tracking silently until earlier timers finish, then reveal their remaining time once space frees up.
- Added a one-time vibration whenever any yellow timer drops below 10 seconds so the referee hears the countdown even when watching another part of the screen.
- Preserved each yellow entry’s `Y#` label so replacing a card that was hidden still shows the same identifier when it finally appears.

## [2025-12-10] Layout Resilience
- Reworked `RugbyTimerView` so the half text, tries, and timers position themselves without overlapping even when multiple card timers are active, and card timers now space dynamically below the main clocks.
- Noted the adaptive layout strategy in `project_technical_document.md` so future contributors understand the spacing guarantees.
- Rebuilt with `monkeyc` to confirm the refreshed layout compiles cleanly for the Fenix 6.

## [2025-10-31] Feature/Enhancement Summary
- Added persistent state storage and final match summary for reuse by future agents.
- Reworked UI to display multiple yellow/red timers with numbering, auto shift main timers to avoid overlap, and maintain layout across device resolutions.
- Introduced card dialog via hardware buttons (up/down), conversion-specific score options, and pause clock capability.
- Added 30-second countdown alert via Attention vibrate profile and ensured timers keep running during conversion/penalty states.
- Documented project in `project_technical_document.md` for onboarding future LLM collaborators.
