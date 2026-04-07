# Feature Specification: Core Match Lifecycle

**Feature ID**: `SPEC-001`  
**Created**: 2026-04-07  
**Status**: Adopted  
**Scope**: Match state machine, main clocks, halftime break, lock-on-start, and haptics.

## User Scenarios & Testing

### User Story 1 - Run a match from kickoff to full time (Priority: P1)

A referee must be able to start a match, pause and resume it safely, move through halftime, and finish the match without the main clocks drifting or jumping between states.

**Why this priority**: This is the app’s primary job. If the main lifecycle is unreliable, every other feature becomes unsafe.

**Independent Test**: Start a match, pause it, resume it, enter halftime, start the second half, and end the match. Confirm the visible states and main timers follow the expected state machine.

**Acceptance Scenarios**:

1. **Given** the app is idle, **When** the referee presses `SELECT`, **Then** the match enters live play and the main half countdown starts from the configured half duration.
2. **Given** the match is live, **When** the referee pauses and resumes play, **Then** the pauseable match clock resumes from the same boundary instead of skipping or replaying time.
3. **Given** the first half reaches `00:00`, **When** the horn condition is reached, **Then** the app enters halftime instead of ending the match.
4. **Given** the second half reaches `00:00`, **When** the horn condition is reached, **Then** the app ends the match and transitions to the ended state.

---

### User Story 2 - Keep each clock owned by the right state (Priority: P1)

As a referee, I need idle setup, live half timing, halftime break timing, and elapsed match time to remain clearly separated so one state cannot corrupt another.

**Why this priority**: The project has already had regressions caused by stale runtime values leaking into idle or halftime rendering.

**Independent Test**: Change half duration while idle, start a match, enter halftime, and confirm idle duration, live countdown, break countdown, and elapsed clock each use their own source of truth.

**Acceptance Scenarios**:

1. **Given** the app is idle, **When** the main screen renders, **Then** the large countdown is derived from configured half duration rather than stale live-match remaining time.
2. **Given** the app is in halftime, **When** the halftime break is counting down, **Then** the break uses `countdownSeconds` while the main half duration remains intact for the second-half restart.
3. **Given** the app restarts after a broken pre-match snapshot, **When** startup validation runs, **Then** the app returns to a clean idle setup instead of reopening a pseudo-live state.

---

### User Story 3 - Receive state-specific haptics (Priority: P2)

As a referee, I want distinct vibration patterns for the major state transitions so I do not have to stare at the watch continuously.

**Why this priority**: It improves usability during live officiating but depends on the core lifecycle already being correct.

**Independent Test**: Trigger start, pause, resume, halftime, full-time, and lock toggle paths and verify the corresponding haptic hooks fire from the correct transitions.

**Acceptance Scenarios**:

1. **Given** the referee starts a half, **When** the state enters live play, **Then** the match-start vibration fires once.
2. **Given** the referee pauses play, **When** the paused state remains active, **Then** the periodic pause reminder cadence is state-gated and does not run in idle or ended states.

## Edge Cases

- Starting a match with a stale or zero `countdownTimer` must reseed from `halfDuration`.
- Restarting the app from a malformed or blank saved snapshot must not strand the app outside true idle.
- Halftime break duration may be shortened to zero, in which case the app must move to the “Half 2 Ready” state instead of running negative time.

## Requirements

### Functional Requirements

- **LIFE-001**: The system MUST expose at least these match states: idle, playing, paused, conversion, penalty, halftime, and ended.
- **LIFE-002**: The system MUST start the first half from the configured `halfDuration`.
- **LIFE-003**: The system MUST treat `elapsedTime`, `gameTime`, and `suspensionTime` as separate clocks with distinct ownership rules.
- **LIFE-004**: The system MUST render idle countdown from configuration-owned timing fields rather than from stale live-match remaining time.
- **LIFE-005**: The system MUST pause the main countdown when the match enters paused, halftime, or ended states.
- **LIFE-006**: The system MUST enter halftime when the first-half countdown reaches zero.
- **LIFE-007**: The system MUST enter ended state when the second-half countdown reaches zero.
- **LIFE-008**: The system MUST support a halftime break countdown that is independent from the live half countdown.
- **LIFE-009**: The system MUST reset halftime-break runtime state before the second half begins.
- **LIFE-010**: The system MUST support `lockOnStart` so each half can auto-lock immediately after being started.
- **LIFE-011**: The system MUST emit distinct haptic events for match start, pause, resume, halftime, full time, pause reminder, and lock toggle.
- **LIFE-012**: The system MUST keep countdown values clamped at zero rather than showing negative time.

### Key Entities

- **Match State**: The current phase of play and the main driver for input, rendering, and timing behavior.
- **Core Clocks**: `elapsedTime`, `gameTime`, and `suspensionTime`, each with different run/pause semantics.
- **Half Configuration**: The configured half duration and halftime break duration that define how a match instance starts and resumes.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A kickoff-to-full-time lifecycle can be executed without any state transition skipping or impossible state combinations.
- **SC-002**: Idle, halftime, and live countdown displays remain stable under restart, pause/resume, and second-half restart flows.
- **SC-003**: A stale runtime countdown cannot force the idle screen to show `00:00` when a valid half duration exists.
