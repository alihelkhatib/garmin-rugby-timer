# Session Log

## [2025-12-11] Score Spacing Fix
- Lowered the tries indicators in `source/RugbyTimerView.mc` so they no longer overlap the main score digits on the Fenix 6 layout.

## [2025-12-12] Try Placement Refinement
- Shifted `triesY` to `height * 0.36` in `source/RugbyTimerView.mc` to add more breathing room under the scores and keep the try text clear of the digits.
- Updated `triesY` to sit just below the half indicator and switched to a centered `homeT/awayT` string so the try info lives between the scores without duplicating text on each side.

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
