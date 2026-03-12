# Feature Specification: Haptic Alert Profiles by Context

**Feature Branch**: `014-haptic-context-profiles`  
**Created**: 2026-03-11  
**Status**: Draft  
**Input**: User description: "i like the idea of haptic alert profiles by context"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Select Context Profiles (Priority: P1)

As a referee, I want to choose a haptic profile for each alert context so that the watch communicates urgency clearly without needing to look at the screen.

**Why this priority**: This delivers the core value directly during active officiating where glance time is limited.

**Independent Test**: Can be fully tested by assigning different profiles to at least three contexts and confirming each assigned context triggers the expected vibration style.

**Acceptance Scenarios**:

1. **Given** the referee opens haptic profile settings, **When** they choose a profile for a specific context, **Then** the profile is saved for that context.
2. **Given** a context-specific alert occurs during match flow, **When** the alert is triggered, **Then** the watch uses the profile assigned to that context.

---

### User Story 2 - Keep Existing Defaults for Fast Setup (Priority: P2)

As a referee, I want sensible default haptic behavior so I can use the app immediately even if I never customize profiles.

**Why this priority**: Fast onboarding avoids extra pre-match setup and protects reliability for first-time use.

**Independent Test**: Can be fully tested by running match alerts on a fresh install and confirming each context produces a default pattern without manual configuration.

**Acceptance Scenarios**:

1. **Given** no custom profile is configured, **When** a supported context alert occurs, **Then** a defined default profile is used.
2. **Given** the referee resets haptic settings, **When** reset completes, **Then** all context mappings return to default values.

---

### User Story 3 - Prevent Overload During High-Frequency Events (Priority: P3)

As a referee, I want protection from repeated haptic bursts so alerts stay useful and do not become distracting during rapid event sequences.

**Why this priority**: This improves comfort and usability during intense match periods.

**Independent Test**: Can be fully tested by triggering repeated alerts in the same context and verifying the app follows anti-overload behavior while still surfacing important events.

**Acceptance Scenarios**:

1. **Given** multiple alerts fire in quick succession, **When** they exceed the allowed burst behavior, **Then** the app limits repeated haptics according to profile rules.
2. **Given** a high-priority context alert occurs while limiting is active, **When** it is triggered, **Then** the high-priority alert still vibrates.

### Edge Cases

- A context has no explicit profile because of migration from older settings.
- The selected profile is unavailable on a specific watch model.
- Two alert contexts are triggered in near-simultaneous timing.
- The referee changes profile settings mid-match.
- Haptic feedback is disabled globally at device level.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST support context-specific haptic assignment for at least these contexts: period transitions, card timer warnings, match end, and stoppage/resume notifications.
- **FR-002**: The system MUST provide a default haptic profile for every supported context.
- **FR-003**: Users MUST be able to update the profile assigned to each supported context individually.
- **FR-004**: The system MUST apply the currently assigned profile when a context alert is triggered.
- **FR-005**: The system MUST persist context-profile assignments across app restarts and device reboots.
- **FR-006**: The system MUST offer a reset action that restores all context-profile assignments to defaults.
- **FR-007**: The system MUST define fallback behavior when a selected profile is unsupported, ensuring an alert still occurs.
- **FR-008**: The system MUST include anti-overload behavior that limits repetitive haptic bursts from repeated low-priority alerts.
- **FR-009**: The system MUST preserve delivery of high-priority alerts even when anti-overload behavior is active.

### Key Entities *(include if feature involves data)*

- **Alert Context**: A named event category that can trigger haptics (for example period transition, card warning, match end, stoppage/resume).
- **Haptic Profile**: A reusable vibration style definition used to represent urgency and event type.
- **Context Profile Mapping**: A persistent mapping from each alert context to one chosen haptic profile.
- **Haptic Throttle State**: Runtime state used to suppress repetitive low-priority alerts while allowing critical alerts.

### Assumptions and Dependencies

- Existing alert-producing events remain unchanged; this feature adjusts how those alerts vibrate.
- Device-level haptics permissions/settings may override app-level behavior.
- Profile names presented to users are understandable without technical terminology.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of referees in validation runs correctly identify alert context by haptic feel without looking at the screen within 2 seconds.
- **SC-002**: 100% of supported alert contexts produce either the assigned or fallback profile in end-to-end tests.
- **SC-003**: 100% of customized context-profile assignments remain intact after app restart in validation testing.
- **SC-004**: Repetitive low-priority alert bursts are reduced by at least 50% in stress scenarios while high-priority alerts remain fully delivered.
