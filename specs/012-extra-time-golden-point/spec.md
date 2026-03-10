# Feature Specification: Extra Time / Golden Point

**Feature Branch**: `012-extra-time-golden-point`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Extra time / golden point — Configurable ET periods triggered after full-time; separate timer with its own countdown."

## Background & Problem Statement

Knockout rugby competitions at all levels use extra time to resolve tied matches. World Rugby 7s uses two 5-minute periods of sudden-death golden point; 15s competitions often use two 10-minute periods followed by kicks. Currently the app has no concept of extra time — when the second half countdown ends the referee must mentally restart the clock or use a phone. Adding configurable ET periods as a first-class game state removes this gap and makes the app complete for knockout formats.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Trigger Extra Time After Full-Time (Priority: P1)

A referee working a 7s knockout cup final reaches the end of the second half with the scores level. After the full-time alert fires they see a new menu option "Extra Time" in the end-of-half screen. They select it, the watch face shows the ET period number and a fresh countdown (e.g. 5:00 for a 5-minute golden-point period). The first score by either team ends the match and the referee presses the end-game action.

**Why this priority**: This is the entire reason for the feature. Delivering just this one story gives referees everything they need to handle tied knockout games — the exact scenario that currently cannot be managed.

**Independent Test**: Run a match to full-time, trigger "Extra Time" from the end-half menu, confirm the timer shows the configured ET length and counts down from that value. Score a point, end the game, and verify the final scoreline is correct.

**Acceptance Scenarios**:

1. **Given** a match has reached the end of the second half, **When** the referee selects "Extra Time" from the post-game menu, **Then** a new countdown begins at the configured ET period length and the display labels this as "ET1".
2. **Given** ET1 is running and a try is scored, **When** the referee records the try via the normal score flow, **Then** the score is updated and the watch face reflects the new total; the referee can immediately end the match.
3. **Given** ET1 expires without a score, **When** the countdown reaches zero, **Then** the watch alerts via vibration, and a menu option "Start ET2" is presented if a second period is configured.
4. **Given** the referee triggers ET2, **When** ET2 countdown begins, **Then** the display labels it "ET2" and the countdown runs to zero or until the game is ended.

---

### User Story 2 - Configure ET Period Length and Count in Settings (Priority: P2)

A tournament director gives referees a watch with the app pre-configured for specific ET rules. Before the first match a referee opens Settings → Extra Time and sets the ET period length (e.g. 5 minutes) and the maximum number of periods (e.g. 2). These values persist and apply for every subsequent match without re-entry.

**Why this priority**: Configurability is what allows this feature to cover every competition format. Without it the feature would need hard-coded values, limiting its usefulness to a narrow set of rules.

**Independent Test**: Set ET period length to 3 minutes and 2 periods in Settings. Run a match to second-half end, trigger ET, confirm the countdown starts at 3:00 and that a second period is offered after ET1 expires.

**Acceptance Scenarios**:

1. **Given** the Settings screen, **When** the referee sets ET period length to 7 minutes, **Then** the next time ET is triggered the countdown starts at 7:00.
2. **Given** ET periods is set to 1, **When** ET1 expires without a score, **Then** no "Start ET2" option is shown; the referee can only end the match or continue with kicks.
3. **Given** ET period length and count have been saved, **When** the app is restarted, **Then** both values are restored and used for the next ET trigger.

---

### User Story 3 - ET Events Appear in Event Log (Priority: P3)

After a golden-point match the referee exports the event log to review the timeline. The log includes "ET1 Start", "ET1 End", "ET2 Start" entries alongside try and card events with accurate timestamps.

**Why this priority**: Accurate event logs are a quality-of-life feature for post-match review. They do not affect the referee's ability to manage the match but add value for reports and performance analysis.

**Independent Test**: Run a match with ET, then view/export the event log. Confirm ET start and end events appear with correct timestamps and labels.

**Acceptance Scenarios**:

1. **Given** an extra-time period was played, **When** the referee views the event log, **Then** "ET1 Start" and "ET1 End" events are present with elapsed-time timestamps.
2. **Given** two ET periods were played, **When** the log is exported, **Then** both ET1 and ET2 events appear in chronological order.

---

### Edge Cases

- What happens if the referee triggers ET during the first half by mistake? The "Extra Time" option is only offered after the second half ends (STATE_ENDED or the post-second-half menu); it is not visible mid-match.
- What happens if ET period length is set to 0? The system clamps it to 1 minute minimum on save.
- What happens if a try is scored in the very last second of ET countdown? Score is recorded normally; the referee then manually ends the match — the timer reaching zero does not auto-end in ET (golden point requires a score, not just time expiry).
- What happens if the referee exits the app mid-ET? The standard state persistence mechanism saves the current ET state; on relaunch the ET countdown resumes correctly.
- What happens if ET is triggered in a non-tied match? There is no tie-check enforcement — the app does not validate whether scores are equal; the referee is responsible for the decision.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST support the ability to start one or more Extra Time periods after the second half of a match ends.
- **FR-002**: Users MUST be able to configure the ET period length (1–30 minutes) and the maximum number of ET periods (1–4) via Settings.
- **FR-003**: The ET period duration and count settings MUST be persisted across app restarts.
- **FR-004**: During ET, the watch face MUST display the current ET period number (e.g., "ET1", "ET2") and the remaining countdown time.
- **FR-005**: All standard in-match actions (try, conversion, card, penalty, pause) MUST function normally during ET periods.
- **FR-006**: When an ET period countdown expires, the app MUST alert the referee via vibration and display an option to start the next ET period (if any remain) or end the match.
- **FR-007**: ET start and end events MUST be recorded in the event log with accurate timestamps.
- **FR-008**: If the maximum number of ET periods is exhausted without a result, the app MUST present only the "End Game" option.
- **FR-009**: The "Extra Time" option MUST only be accessible after the second half ends — it MUST NOT appear during regular play.

### Key Entities

- **ExtraTimePeriod**: A discrete timed period with a sequence number (1, 2, …), configured duration, and start / end timestamps.
- **ETSettings**: Persisted configuration for ET period length (minutes) and maximum period count.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A referee can start an ET period within 5 seconds of receiving the full-time alert, with no additional configuration required at that point.
- **SC-002**: The ET countdown is accurate to within 1 second of actual elapsed time for a 10-minute period.
- **SC-003**: ET configuration in Settings takes under 1 minute for a first-time user with no instructions.
- **SC-004**: All regular-match features (scoring, cards, GPS recording) continue to function without regression during ET periods.

## Assumptions

- ET is always triggered manually by the referee; the app never auto-starts ET at full-time.
- Golden-point (sudden death) is handled by the referee ending the game after recording a score — the app does not auto-terminate ET on a score.
- ET period settings are shared across game types (7s and 15s); per-game-type ET configurations are not in scope for this feature.
- The second-half end state already exists (STATE_ENDED or equivalent); this feature adds a branch from that state into a new STATE_EXTRA_TIME.
