# Feature Specification: Haptic Profiles

**Feature Branch**: `016-haptic-profiles`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Haptic profiles — Distinct vibration sequences for different events: try = long pulse, card = double pulse, half-time = triple pulse, full-time = quad pulse."

## Background & Problem Statement

The app currently uses a generic single vibration pulse for multiple different events (timers expiring, half-time alerts, etc.), making it impossible for a referee to distinguish between event types by feel alone. In a loud stadium, visual confirmation is often not possible while also managing a play. Distinct, memorable vibration patterns for each major event type allow the referee to know what just happened without looking at the watch, reducing their cognitive load significantly.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Distinct Vibration Patterns for Core Events (Priority: P1)

A try is scored during a tightly contested match. The referee's watch gives one long pulse — the try-recording pattern — confirming the score was registered without them needing to look at the screen. Later, at half-time, three shorter pulses fire, a completely different feel that the referee immediately recognises as the half-time signal.

**Why this priority**: The entire value of this feature is sensory differentiation. Delivering P1 — unique patterns for the four core events — gives the referee the full benefit immediately. The other stories (configuration, per-event enable/disable) are layered enhancements.

**Independent Test**: Record a try and feel one long pulse. Issue a card and feel two short pulses. Trigger half-time and feel three short pulses. End the game and feel four short pulses. Each pattern must be distinctly different from the others.

**Acceptance Scenarios**:

1. **Given** a try is recorded, **When** the action is confirmed, **Then** the watch vibrates with one long pulse (approximately 600ms).
2. **Given** a card is issued, **When** the card is confirmed, **Then** the watch vibrates with two short pulses (approximately 150ms on, 150ms off, 150ms on).
3. **Given** the first-half countdown reaches zero, **When** the half-time state is entered, **Then** the watch vibrates with three short pulses.
4. **Given** the second-half countdown reaches zero, **When** the game ends, **Then** the watch vibrates with four short pulses.
5. **Given** a conversion or penalty sub-timer expires, **When** the overlay dismisses, **Then** the watch vibrates with a single medium pulse (distinct from try).

---

### User Story 2 - Haptic Patterns Are Enabled by Default (Priority: P2)

A referee installs the app for the first time and starts officiating. Without any configuration the haptic patterns are active for all four core events. The improved vibration patterns are the default experience; the referee does not need to opt in.

**Why this priority**: Defaults define the experience for the majority of users. Making the improved patterns automatic means every user benefits without needing to discover a settings page.

**Independent Test**: On a fresh install (or after a full data reset), confirm each of the four core events produces its distinct pattern with no changes made in Settings.

**Acceptance Scenarios**:

1. **Given** the app has just been installed, **When** the referee records a try, **Then** the long-pulse pattern fires.
2. **Given** no haptic settings have been changed, **When** each of the four core events fires, **Then** all four distinct patterns occur.

---

### User Story 3 - Disable Haptics Globally or Per-Event (Priority: P3)

A referee officiating in a very quiet environment or wearing the watch against bare skin in hot weather prefers to silence haptics for non-critical events. In Settings → Haptics they can toggle individual event types on or off or disable all haptics with a single "Off" toggle.

**Why this priority**: Full control over haptics is quality-of-life. The feature is fully functional without per-event disable — the patterns alone deliver the value. Configurability is a refinement for edge cases.

**Independent Test**: Disable haptics for "Card" events in Settings. Issue a card and confirm no vibration fires. Confirm try still vibrates. Re-enable and confirm the card pattern is restored.

**Acceptance Scenarios**:

1. **Given** all haptics are disabled in Settings, **When** any event fires, **Then** no vibration occurs.
2. **Given** only "Card" haptics are disabled, **When** a try is scored, **Then** the try pattern fires; **When** a card is issued, **Then** no vibration occurs.
3. **Given** haptic preferences have been saved, **When** the app restarts, **Then** the preferences are restored.

---

### Edge Cases

- What happens if two events fire near-simultaneously (e.g. half-time alert fires while a card is being processed)? The app queues vibrations and plays them sequentially without truncation.
- What happens on devices that do not support variable vibration duration? The app falls back to a generic vibration count pattern using the available vibration API, differentiating by pulse count rather than duration.
- What happens if the battery is critically low? Haptic output is controlled by the OS; the app makes no special handling for battery state — it fires the vibration as normal.
- What happens to the existing single vibration for the 30-second countdown warning? That warning retains its current behaviour (a single pulse) and is not categorised as one of the four core haptic events.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST produce a distinct vibration pattern for each of four core events: try scored, card issued, half-time, full-time.
- **FR-002**: The four patterns MUST be perceptibly different from one another by duration, pulse count, or rhythm.
- **FR-003**: The improved haptic patterns MUST be active by default on first launch with no user configuration required.
- **FR-004**: Users MUST be able to disable all haptics globally via a single Settings toggle.
- **FR-005**: Users MUST be able to disable haptics per event type independently.
- **FR-006**: Haptic preferences MUST be persisted across app restarts.
- **FR-007**: If the device vibration API does not support variable-duration pulses, the app MUST fall back to a pulse-count differentation that is still perceptibly distinct.
- **FR-008**: Haptic events MUST NOT interfere with each other; if two events are queued close together the patterns MUST play sequentially.

### Key Entities

- **HapticEvent**: An enumerated event type (TRY, CARD, HALF_TIME, FULL_TIME, TIMER_EXPIRE) each with an associated vibration pattern definition.
- **HapticPreferences**: Persisted per-event on/off flags and a global enable/disable flag.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In blind testing, referees correctly identify at least 3 of the 4 event types by feel alone without prior training, measured across 5 consecutive trials.
- **SC-002**: Haptic pattern duration for any single event does not exceed 2 seconds, ensuring it does not distract from ongoing play.
- **SC-003**: All four patterns remain active and distinct after app restart (100% persistence).
- **SC-004**: Disabling any single event type in Settings takes under 15 seconds and takes effect immediately.

## Assumptions

- The Garmin Fenix 6 vibration API supports at minimum a single-intensity, variable-duration vibration call. If not, pulse count is used as the differentiator.
- Four patterns are sufficient to cover the most important events; sub-timer expiry (conversion, penalty) shares the generic single-pulse pattern.
- The 30-second warning alert is not redesigned by this feature — it retains its current single-pulse behaviour.
- Haptic patterns are static (not user-customisable sequences); only enabling/disabling per event is in scope.

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
