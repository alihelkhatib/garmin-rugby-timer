# Feature Specification: Post-Match GPS Summary

**Feature Branch**: `017-gps-match-summary`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Post-match GPS summary — After game ends, a one-page summary screen showing total distance covered, average speed, and match duration."

## Background & Problem Statement

The app already records a GPS track and accumulates distance and speed data throughout every match. When the game ends this data is currently only accessible via the exported activity file — there is no immediate on-watch summary. Referees and players who want a quick glance at their physical performance metrics after the final whistle must either connect to Garmin Connect or review a file export later. Adding a one-page post-match summary screen surfaces this already-collected data immediately at the end of the game, making it useful without any extra infrastructure.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Post-Match Summary Screen After Full-Time (Priority: P1)

At the end of a 40-minute 15s match the referee hears the full-time vibration. The watch face transitions to a one-page summary screen showing: total distance (e.g. "8.4 km"), average speed (e.g. "4.2 km/h"), and match duration (e.g. "83 min"). The referee swipes or presses back to dismiss the screen and the app returns to the idle state.

**Why this priority**: The summary screen is the entire feature. It requires no new data collection — the data already exists — and it delivers tangible value the moment the final whistle is blown. This single story constitutes the full MVP.

**Independent Test**: Run a simulated match to completion. Confirm the summary screen appears automatically after the full-time alert and correctly shows total distance, average speed, and match duration. Press back to confirm dismissal and idle-state return.

**Acceptance Scenarios**:

1. **Given** a match has ended (STATE_ENDED), **When** full-time is confirmed, **Then** the watch face transitions to the summary screen within 1 second.
2. **Given** the summary screen is visible, **When** the referee presses Back, **Then** the app returns to the idle state ready for a new game.
3. **Given** the summary screen is visible, **When** the referee reads the screen, **Then** total distance, average speed, and match duration are visible and clearly labelled.
4. **Given** GPS was unavailable or not started during the match, **When** the summary screen appears, **Then** distance and speed are shown as "--" and match duration is still displayed.

---

### User Story 2 - Summary Values Are Accurate and Formatted (Priority: P2)

The referee looks at the summary after a match they know covered approximately 10 km (they ran the full pitch several times). The displayed distance falls within a reasonable GPS accuracy margin (typically ±5% for wrist-worn GPS). Speed and duration are formatted clearly: km or miles based on device locale, HH:MM for duration.

**Why this priority**: Accuracy and formatting are what make the data trustworthy and readable. An inaccurate or misformatted summary is harmful — it could cause a referee to question the entire app. These details are critical for the feature to be used in practice.

**Independent Test**: Run a timed outdoor match (or simulator session with known distance). Confirm the displayed distance is within ±10% of the actual distance. Confirm duration matches the match clock within 1 minute.

**Acceptance Scenarios**:

1. **Given** the device locale uses metric, **When** the summary is shown, **Then** distance is displayed in kilometres with one decimal place (e.g., "8.4 km").
2. **Given** the match lasted 83 minutes, **When** the summary is shown, **Then** match duration reads "1:23" or "83 min" format — consistent with the device display style.
3. **Given** the device setting is imperial, **When** the summary is shown, **Then** distance is displayed in miles.

---

### User Story 3 - Summary Accessible After Dismissal (Priority: P3)

A referee dismisses the summary screen immediately after the game to deal with players, and later wants to review the numbers. They can reopen the summary from the main menu ("Match Summary" option) while the app still has data from the last match loaded (before a new game is started).

**Why this priority**: Recall of summary data is quality-of-life. The referee already has the data on their Garmin Connect history; this is a convenience for users who dismissed too quickly. It is not required for the feature to deliver value.

**Independent Test**: End a match, dismiss the summary, then reopen it via the main menu. Confirm the same values are shown. Start a new match and confirm the option is no longer available or shows the most recent match data appropriately.

**Acceptance Scenarios**:

1. **Given** a match has ended and the summary was dismissed, **When** the referee opens the main menu, **Then** a "Match Summary" option is visible.
2. **Given** the referee selects "Match Summary", **Then** the same summary screen from the end of the last match is shown.
3. **Given** a new game has been started after dismissal, **When** the referee opens the main menu, **Then** "Match Summary" is either absent or shows the previous match's data clearly labelled as such.

---

### Edge Cases

- What happens if GPS was never acquired (indoor match or GPS disabled on device)? Distance and speed fields display "--"; match duration is still shown using the internal game clock.
- What happens if the match was very short (under 5 minutes)? Summary shows the accurate short duration and distance; no minimum threshold is enforced.
- What happens if the referee exits the app mid-match without ending the game? The summary is not shown; it only triggers on a controlled game-end action.
- What happens if the GPS distance calculation causes an overflow (extremely long match)? Distance is capped at 999.9 km with no crash.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After a match ends (full-time confirmed), the app MUST automatically display a one-page summary screen.
- **FR-002**: The summary MUST show at minimum: total distance covered, average speed, and match duration.
- **FR-003**: If GPS data is unavailable, distance and speed MUST display a placeholder ("--"); match duration MUST still be shown.
- **FR-004**: The summary screen MUST be dismissible via the Back button, returning the app to the idle state.
- **FR-005**: Distance MUST be displayed in the user's locale unit (metric km or imperial miles).
- **FR-006**: After dismissal, the last match summary MUST remain accessible via a main-menu option until a new game is started or the app is restarted.
- **FR-007**: The summary screen MUST render within 1 second of the full-time transition.

### Key Entities

- **MatchSummary**: A computed view over existing GPS track data (`distance`, `speed`) and the match clock (`gameTime`). No new data is collected; this is entirely a display layer over what is already recorded.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The summary screen appears automatically within 1 second of full-time on 100% of test runs.
- **SC-002**: Displayed total distance is within 10% of the actual distance measured by a reference device over the same route.
- **SC-003**: A referee can read and understand all three metrics on the summary screen in under 5 seconds without any legend or instructions.
- **SC-004**: All existing end-game flows (event log export, app idle state) continue to work without regression after the summary screen is dismissed.

## Assumptions

- The GPS track (`gpsTrack`) and `distance` field already accumulate data throughout the match; no changes to data collection are required.
- Match duration uses `gameTime` (total elapsed seconds of live play, excluding paused periods) as the source.
- Average speed is computed as `distance / gameTime` in the appropriate unit; no rolling average is required.
- The summary is a simple single-screen read-only view — no editing, sharing, or chart visualisation is in scope for this feature.

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
