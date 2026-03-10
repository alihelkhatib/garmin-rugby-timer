# Feature Specification: Injury / Stoppage Time

**Feature Branch**: `014-injury-stoppage-time`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Injury/stoppage time — Add selectable stoppage minutes from the main in-game menu; displayed as a small on-screen indicator during play."

## Background & Problem Statement

During a rugby match the referee can stop the clock for serious injuries, medical stoppages, or other exceptional interruptions. World Rugby law requires that stopped time be added back to the end of the half. Currently the app has no way to track how many minutes were stopped, meaning the referee must count independently in their head and then mentally extend the countdown. Adding a stoppage-time counter that accumulates stopped minutes and shows an indicator on-screen directly supports accurate timekeeping under law.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record a Stoppage and See the Indicator (Priority: P1)

A player is injured during the 23rd minute. The referee stops regular play (pauses the countdown), and from the main menu selects "Add Stoppage" and enters "2" (minutes). The watch face now shows a small "ST+2" label alongside the main timer. When play resumes the referee knows they must add 2 minutes at the end of the half.

**Why this priority**: Recording a stoppage and displaying the accumulated total is the complete core feature. A referee who can see "ST+3" on their watch has all the information they need to accurately manage injury time — this single story delivers full standalone value.

**Independent Test**: During a game, select "Add Stoppage" from the main menu and choose 2 minutes. Confirm an indicator appears on the watch face showing the accumulated stoppage value. Add a second stoppage and confirm the total updates.

**Acceptance Scenarios**:

1. **Given** a game is in progress, **When** the referee selects "Add Stoppage" from the main menu and enters 2 minutes, **Then** a stoppage indicator (e.g., "+2") appears on the watch face.
2. **Given** a stoppage of 2 min is already recorded, **When** the referee adds another 1 minute stoppage, **Then** the indicator updates to "+3".
3. **Given** the stoppage indicator is showing, **When** the referee glances at the watch face, **Then** the indicator is visible without obscuring the main score or timer.
4. **Given** a game is in STATE_IDLE or STATE_HALFTIME, **When** the referee opens the main menu, **Then** "Add Stoppage" is not offered (stoppages are only valid during active play).

---

### User Story 2 - Stoppage Time Informs Half Extension (Priority: P2)

At the end of the 40th minute the countdown reaches zero. Rather than the whistle firing immediately, the referee sees the accumulated stoppage total and knows to wait the additional time. The app extends the countdown value by the accumulated stoppage total when the half would otherwise end, giving the referee a clear on-screen countdown for the injury-time extension.

**Why this priority**: Automatically extending the countdown by the stoppage total removes the mental burden of tracking the extension separately. It is the difference between a reminder tool and true integrated timekeeping.

**Independent Test**: Accumulate 3 minutes of stoppage during a half, let the countdown reach zero, confirm the half does not immediately end and instead shows a 3-minute extension countdown.

**Acceptance Scenarios**:

1. **Given** 3 minutes of stoppage have been recorded, **When** the main countdown reaches zero, **Then** an additional 3-minute countdown begins (labelled "Injury Time" or "IT") before the half-time alert fires.
2. **Given** the injury-time extension is running, **When** the countdown reaches zero, **Then** the standard half-time behaviour (vibration, state transition) occurs.
3. **Given** no stoppage has been recorded, **When** the main countdown reaches zero, **Then** half-time triggers normally with no extension.

---

### User Story 3 - Stoppage Total in Event Log (Priority: P3)

After the match the referee exports the event log. The log includes a "Stoppage +2min" entry for each recorded stoppage with a timestamp, giving an auditable record of stoppages applied during the game.

**Why this priority**: Event log entries are quality-of-life for post-match documentation. The core keeping behaviour works without them, so this is the lowest priority.

**Independent Test**: Record two stoppages during a match, export the event log, confirm both stoppages appear as named entries with timestamps.

**Acceptance Scenarios**:

1. **Given** a stoppage of 2 minutes was added at game time 23:00, **When** the event log is viewed, **Then** an entry "Stoppage +2min" appears near the 23:00 mark.
2. **Given** both stoppages are in the log, **When** the log is exported, **Then** both entries appear in chronological order alongside other match events.

---

### Edge Cases

- What happens if the referee adds stoppage when the game is paused for a conversion or penalty overlay? "Add Stoppage" is disabled during conversion and penalty overlays — these are normal game events, not stoppages.
- What happens if a very large stoppage value (e.g. 15 minutes) is entered? The picker is clamped to a maximum of 10 minutes per entry; the referee adds multiple entries if needed.
- What happens to accumulated stoppage if the half is reset or the game is restarted? Stopage total resets to 0 at the start of each half-time and at game reset.
- What happens if the referee adds stoppage for the second half? Stoppage accumulates independently per half; each half starts with 0 accumulated minutes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to add stoppage time (1–10 minutes per entry) from the main in-game menu while the game is in an active state.
- **FR-002**: Accumulated stoppage time for the current half MUST be displayed as a small indicator on the watch face, visible alongside the main timer and score.
- **FR-003**: When the main countdown reaches zero and accumulated stoppage is greater than zero, the app MUST extend the half by the accumulated stoppage amount before triggering the half-time alert.
- **FR-004**: Accumulated stoppage MUST reset to zero at the start of each half and on full game reset.
- **FR-005**: Each stoppage addition MUST be recorded as a distinct entry in the event log with a timestamp.
- **FR-006**: The "Add Stoppage" menu option MUST be available only during STATE_PLAYING; it MUST NOT appear when the game is idle, paused mid-conversion, or in half-time.
- **FR-007**: The stoppage indicator MUST NOT obscure the score, main timer, or card overlay regions of the watch face.

### Key Entities

- **StoppageTotal**: An accumulated integer value (minutes) per half that is displayed on-screen and used to extend the countdown when the half ends.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A referee can record a stoppage from the main menu in under 10 seconds without leaving the playing flow.
- **SC-002**: The stoppage indicator is legible on the watch face at arm's length in outdoor lighting conditions.
- **SC-003**: The half extension applied by the app exactly matches the accumulated stoppage total in 100% of manual tests.
- **SC-004**: All existing match features (score recording, cards, GPS) continue to work without regression when stoppage time is active.

## Assumptions

- Stoppage time entries are whole minutes only; sub-minute precision is not required.
- The stoppage indicator is a compact text label, not a separate bar or widget — the existing layout must accommodate it without a full redesign.
- Maximum 10 minutes per single entry is sufficient for any realistic stoppage; multiple entries are used for longer stoppages.
- The second-half stoppage accumulator is independent of the first-half one.

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently - e.g., "Can be fully tested by [specific action] and delivers [specific value]"]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right edge cases.
-->

- What happens when [boundary condition]?
- How does system handle [error scenario]?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: System MUST [specific capability, e.g., "allow users to create accounts"]
- **FR-002**: System MUST [specific capability, e.g., "validate email addresses"]  
- **FR-003**: Users MUST be able to [key interaction, e.g., "reset their password"]
- **FR-004**: System MUST [data requirement, e.g., "persist user preferences"]
- **FR-005**: System MUST [behavior, e.g., "log all security events"]

*Example of marking unclear requirements:*

- **FR-006**: System MUST authenticate users via [NEEDS CLARIFICATION: auth method not specified - email/password, SSO, OAuth?]
- **FR-007**: System MUST retain user data for [NEEDS CLARIFICATION: retention period not specified]

### Key Entities *(include if feature involves data)*

- **[Entity 1]**: [What it represents, key attributes without implementation]
- **[Entity 2]**: [What it represents, relationships to other entities]

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: [Measurable metric, e.g., "Users can complete account creation in under 2 minutes"]
- **SC-002**: [Measurable metric, e.g., "System handles 1000 concurrent users without degradation"]
- **SC-003**: [User satisfaction metric, e.g., "90% of users successfully complete primary task on first attempt"]
- **SC-004**: [Business metric, e.g., "Reduce support tickets related to [X] by 50%"]
