# Feature Specification: Substitution Tracker

**Feature Branch**: `015-substitution-tracker`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Substitution tracker — Track subs used per team with a configurable maximum; warn via vibration and overlay when the limit is reached."

## Background & Problem Statement

Rugby 7s and 15s competitions impose strict limits on how many substitutions each team may make during a match. In 7s, teams are typically permitted unlimited rolling substitutions from a squad of 12; in 15s, the limit is usually 8 contested substitutions. A referee who loses count of substitutions may inadvertently allow an illegal sub, creating a potential protest or judicial problem. Adding a substitution counter with a configurable maximum gives the referee a reliable on-device record and alerts them at the limit, removing a cognitive burden during an already-demanding match.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record a Substitution and See the Running Total (Priority: P1)

During a 15s match a replacement runs onto the pitch. The referee taps the menu, selects "Sub" (or a side — Home / Away), and the watch face updates to show the running substitution count for that team (e.g. "H:3 A:2"). The referee can always glance at the screen to know exactly how many subs each team has used.

**Why this priority**: Recording subs and displaying the count is the standalone core value. A referee with a live sub count on their wrist has everything needed to prevent an illegal substitution — this alone justifies the feature.

**Independent Test**: Record 3 home subs and 2 away subs during a match. Confirm the watch face tally shows 3 for home and 2 for away after each entry. The feature delivers value independently of the warning or Settings configuration.

**Acceptance Scenarios**:

1. **Given** a game is in progress, **When** the referee selects "Sub – Home" from the main menu, **Then** the home substitution count increments by 1 and the updated count is visible on the watch face.
2. **Given** the referee selects "Sub – Away", **When** they confirm, **Then** the away count increments and is displayed.
3. **Given** the game is in STATE_IDLE or STATE_ENDED, **When** the referee opens the menu, **Then** the Sub option is not offered.
4. **Given** a substitution is recorded, **When** the event log is viewed, **Then** a "Home Sub (3/8)" style entry appears with a timestamp.

---

### User Story 2 - Alert When Substitution Limit Is Reached (Priority: P2)

A Rugby 15s game has a maximum of 8 substitutions per team. When a team reaches that limit, the watch vibrates (a distinct double-pulse) and a brief overlay message appears: "Home subs FULL". Any further attempt to record a sub for that team shows a warning before allowing the referee to override.

**Why this priority**: The alert is what turns a simple counter into an active safeguard. Referees who already know the count can ignore the alert; those who lost track get a crucial prompt.

**Independent Test**: Set maximum subs to 3 in Settings. Record 3 home subs — confirm the vibration fires and the overlay appears on the third sub. Attempt to record a 4th — confirm a warning is shown.

**Acceptance Scenarios**:

1. **Given** the substitution maximum is 8 and the home team has used 8, **When** the maximum is reached, **Then** the watch vibrates with a distinctive alert pattern and shows a "Home subs FULL" overlay.
2. **Given** the limit has been reached for home, **When** the referee attempts to record another home sub, **Then** the app shows a warning ("Home subs FULL") before proceeding; the referee can dismiss or cancel.
3. **Given** maximum subs is set to 0 (unlimited), **When** the referee records any number of subs, **Then** no alert fires regardless of count.

---

### User Story 3 - Configure Substitution Maximum in Settings (Priority: P3)

Before the first match of a tournament a referee opens Settings → Substitutions and sets the maximum per team to 8. They also set 0 for unlimited (e.g. for 7s rolling subs). The value persists across matches until changed.

**Why this priority**: The maximum is competition-dependent and must be configurable. Without configurability the feature would need hard-coded defaults, which break for different formats. It is P3 because a hard-coded default of 8 would still cover 85% of 15s cases — configurability adds breadth.

**Independent Test**: Set the maximum to 5 in Settings, play a match, and confirm the alert triggers at 5 subs not before or after.

**Acceptance Scenarios**:

1. **Given** the Settings → Substitutions screen, **When** the referee sets the maximum to 5, **Then** the alert fires when a team records its 5th sub.
2. **Given** the maximum is saved, **When** the app is restarted, **Then** the configured maximum is restored.
3. **Given** the maximum is set to 0, **When** subs are recorded, **Then** no limit alert fires.

---

### Edge Cases

- What happens if the substitution count exceeds the maximum (referee overrides)? Each override records a "Sub (over limit)" event in the log; the count keeps incrementing past the maximum.
- What happens to sub counts at half-time? Sub counts are cumulative for the whole match; they do not reset at half-time (rugby law counts subs per match, not per half).
- What happens if the game is reset? Sub counts reset to 0 on game reset along with other match state.
- What happens if the maximum is changed mid-match? The new maximum takes effect immediately; if a team has already used more subs than the new maximum, no alert fires retroactively.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to record a substitution for the home team or away team from the main in-game menu during active play.
- **FR-002**: The current substitution count for each team MUST be displayed on the watch face throughout the match.
- **FR-003**: Users MUST be able to configure the maximum number of substitutions per team (0 = unlimited, 1–20) via Settings.
- **FR-004**: The substitution maximum MUST be persisted across app restarts.
- **FR-005**: When a team reaches the configured maximum, the app MUST alert the referee via a distinct vibration pattern and an on-screen overlay message.
- **FR-006**: The referee MUST be able to override the limit and record additional subs after acknowledging the warning.
- **FR-007**: Each substitution MUST be recorded in the event log with a team label, running count, and timestamp.
- **FR-008**: Sub counts MUST reset to zero on full game reset and MUST NOT reset at half-time.

### Key Entities

- **SubCount**: A per-team integer counter (home, away) tracking total substitutions made in the current match.
- **SubMaximum**: A persisted integer setting (per game or global) defining the substitution limit that triggers an alert.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A referee can record a substitution from the main menu in under 5 seconds without leaving the playing state.
- **SC-002**: The substitution limit alert fires on 100% of test cases when the configured maximum is exactly reached.
- **SC-003**: The sub count display is visible on the watch face without interfering with score, timer, or card overlays.
- **SC-004**: Sub count configuration in Settings takes under 30 seconds for a first-time user.

## Assumptions

- Substitution limits are per-team and per-match (not cumulatively per half).
- Maximum of 20 subs per team covers all realistic formats; the picker upper bound is 20.
- Setting 0 means unlimited; this covers Rugby 7s rolling substitutions where no practical limit is enforced by the referee.
- Sub counting does not distinguish between permanent and blood substitutions — all substitutions are counted equally.

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
