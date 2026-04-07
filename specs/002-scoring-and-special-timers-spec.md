# Feature Specification: Scoring And Special Timers

**Feature ID**: `SPEC-002`  
**Created**: 2026-04-07  
**Status**: Adopted  
**Scope**: Score entry, conversion flow, penalty timers, undo, event logging, and score-related overlays.

## User Scenarios & Testing

### User Story 1 - Record scores quickly during a live match (Priority: P1)

A referee must be able to record tries, penalty tries, penalties, drop goals, and conversions from the watch without losing track of game state.

**Why this priority**: Scorekeeping is core match functionality and must remain correct under pressure.

**Independent Test**: Record each supported score type for either team and verify scoreboard totals, tries count, and event log entries.

**Acceptance Scenarios**:

1. **Given** the match is live, **When** the referee records a try, **Then** the scoring team gains five points and one try.
2. **Given** the match is live, **When** the referee records a penalty try, **Then** the scoring team gains seven points without requiring a conversion flow.
3. **Given** the match is live, **When** the referee records a penalty goal or drop goal, **Then** the scoring team gains three points.

---

### User Story 2 - Run post-try conversion timing safely (Priority: P1)

As a referee, I need the app to automatically enter conversion mode after a try, keep the match clock aligned, and let me mark make or miss from the overlay.

**Why this priority**: This is a high-frequency rugby-specific flow with a history of state and rendering regressions.

**Independent Test**: Record a try with conversions enabled, confirm the overlay opens, then mark both make and miss paths and verify the score/state outcomes.

**Acceptance Scenarios**:

1. **Given** a try is scored while conversion timing is enabled, **When** the scoring event completes, **Then** the app enters conversion state and opens the conversion overlay on the main screen.
2. **Given** the app is in conversion state, **When** the referee marks a made conversion, **Then** two points are awarded and play resumes.
3. **Given** the app is in conversion state, **When** the referee marks a missed conversion or the timer expires, **Then** no extra points are awarded and play resumes.

---

### User Story 3 - Use penalty-timer overlays without corrupting play state (Priority: P2)

As a referee, I need penalty-goal timing to be available when enabled, but I do not want that special timer to desynchronize the main match clock or leak stale state after it ends.

**Why this priority**: Penalty timing is important but less common than live scoring and conversions.

**Independent Test**: Record a penalty goal with penalty timing enabled, let the timer expire, and verify the match resumes with cleared special-timer runtime.

**Acceptance Scenarios**:

1. **Given** penalty timing is enabled during live play, **When** the referee records a penalty goal, **Then** the app enters penalty state and starts the penalty countdown.
2. **Given** the app leaves conversion or penalty state, **When** play resumes, **Then** special countdown runtime fields are cleared so stale overlay data does not reappear later.

## Edge Cases

- Starting a conversion or penalty timer must first synchronize live clocks so the main countdown and special countdown share the same time boundary.
- The main menu and unrelated score/card flows must not remain accessible while a special overlay owns the screen.
- Undo must not leave impossible score/try totals after a try-triggered conversion setup.

## Requirements

### Functional Requirements

- **SCORE-001**: Users MUST be able to record tries, penalty tries, penalties, and drop goals for either team.
- **SCORE-002**: A recorded try MUST increment both team score and team try count.
- **SCORE-003**: When conversion timing is enabled, recording a try MUST enter conversion state automatically.
- **SCORE-004**: Conversion state MUST track which team is attempting the kick.
- **SCORE-005**: A made conversion MUST award two points to the conversion team and return the app to open play.
- **SCORE-006**: A missed conversion MUST not award points and MUST return the app to open play.
- **SCORE-007**: When penalty timing is enabled, recording a penalty goal MUST enter penalty state and start the configured countdown.
- **SCORE-008**: Starting any special timer MUST synchronize the main match clocks to the same current timestamp first.
- **SCORE-009**: Resuming play from a special timer MUST clear special countdown runtime fields and alert flags.
- **SCORE-010**: Score-related events MUST append readable event-log entries using the active team labels.
- **SCORE-011**: The app MUST support undo for the most recent scoring event.
- **SCORE-012**: Special overlays MUST preserve visibility of the main match countdown while their own countdown is active.

### Key Entities

- **Score Event**: A scored action with team ownership, type, and enough data to undo or persist it.
- **Special Timer State**: Runtime fields used only while conversion or penalty timing is active.
- **Event Log Entry**: Human-readable match history tied to scoring and discipline actions.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Each supported score type produces the correct score delta on first use.
- **SC-002**: Conversion make/miss flows always return to a valid non-special match state.
- **SC-003**: No stale conversion or penalty overlay can reappear after normal play resumes.
