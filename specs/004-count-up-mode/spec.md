# Feature Specification: Count-Up Mode

**Feature Branch**: `004-count-up-mode`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Count-up mode — Count from 0:00 upward instead of counting down; useful for formats without a fixed half-length or as a backup stopwatch."

## Background & Problem Statement

The current timer always counts down from a configured half-length. Some competition formats (e.g. informal tournaments, referee training, free-form sessions) do not operate with a fixed half-length — the referee simply blows when they decide. In other cases a referee may want a backup stopwatch that ticks upward so they can reference raw elapsed time even if the countdown resumes. Adding a count-up mode means the app becomes usable in every scenario, not just pre-configured half-lengths.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enable Count-Up Before a Match (Priority: P1)

A referee is supervising a free-form training run-through with no fixed end time. In Settings they toggle the timer mode from "Countdown" to "Count-Up". They return to the watch face, press Select to start play, and the display shows time ticking upward from 0:00. When they decide the half is over they press the menu button and select "End Half" to transition to half-time as normal.

**Why this priority**: This is the single core behaviour of the entire feature. Without it nothing else is deliverable. It unlocks the app for every format that does not have a fixed half-length, which is the primary scenario motivating the request.

**Independent Test**: Enable Count-Up in Settings, start a game, observe the main timer incrementing from 0:00. Reaching 5 minutes should show 5:00, not a negative value. Pausing and resuming must freeze and continue the upward count.

**Acceptance Scenarios**:

1. **Given** Count-Up mode is enabled in Settings, **When** the user starts a match, **Then** the main timer displays 0:00 and immediately begins incrementing upward.
2. **Given** the timer is running in Count-Up mode, **When** the user pauses and resumes, **Then** the timer freezes at the paused value and continues from that exact value on resume.
3. **Given** Count-Up mode is enabled, **When** the user presses Select at STATE_IDLE, **Then** the game transitions to STATE_PLAYING just as in countdown mode — all other game-flow logic (score recording, cards, etc.) remains unchanged.
4. **Given** Count-Up mode is enabled and play is running, **When** the user selects "End Half" from the menu, **Then** the game enters half-time and the elapsed count-up value is recorded in the event log as the first-half duration.

---

### User Story 2 - Count-Up Shown on Watch Face (Priority: P2)

A referee glances at their watch mid-match. In count-up mode the watch face renders the incrementing count-up time in the same large timer position as the countdown value normally occupies. No separate display area is required — the format is M:SS just as the countdown is shown.

**Why this priority**: Visual rendering is what makes the mode usable in practice. Without the correct display the feature is activated but not surfaced to the referee.

**Independent Test**: Enable Count-Up, start a game, wait 90 seconds and confirm the display reads 1:30 in the main timer area. Rendering must still leave room for score and card overlays.

**Acceptance Scenarios**:

1. **Given** Count-Up mode is active and the game is playing, **When** 75 seconds have elapsed, **Then** the main timer area shows "1:15".
2. **Given** Count-Up mode is active, **When** the game is paused, **Then** the timer area is frozen at the elapsed value.
3. **Given** Count-Up mode is active and the game is playing for more than 99 minutes, **Then** the timer continues to increment without overflow or crash (display clips to H:MM:SS or wraps gracefully).

---

### User Story 3 - Persist Count-Up Preference Across Sessions (Priority: P3)

A referee who always uses count-up mode sets it once in Settings. On subsequent app launches the mode is still enabled. They do not need to re-configure it before every match.

**Why this priority**: Persistence eliminates a recurring setup step for referees who always work in free-form formats. It is quality-of-life layered on the core feature.

**Independent Test**: Enable Count-Up in Settings, close and reopen the app, confirm the watch face is in count-up mode (timer shows 0:00 and increments rather than decrementing from a configured duration).

**Acceptance Scenarios**:

1. **Given** Count-Up mode was enabled in a previous session, **When** the app is reopened, **Then** the mode is restored to Count-Up and the timer behaves accordingly.
2. **Given** the user switches back to Countdown mode in Settings, **When** the app is reopened, **Then** the mode is Countdown and the pre-configured half-length is used.

---

### Edge Cases

- What happens when count-up reaches 99:59 (the display maximum)? The timer continues to increment; display switches to H:MM format or clips gracefully — no crash or reset.
- What happens if the user has no half-length configured and switches to Countdown mode? The system uses the game-type default half-length as a fallback.
- What happens with conversion, penalty, and kickoff overlays in count-up mode? These sub-timers always count down (e.g. a conversion clock expires); the main timer continues to count up in the background.
- What happens if count-up mode is active when the app resumes from suspend? The elapsed time since the last timestamp is added to the count-up value, identical to the countdown resume logic.
- What happens to low-time alerts in count-up mode? The 30-second warning and zero-crossing vibration are suppressed — there is no countdown end to trigger them.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST support a Count-Up timer mode in which the main timer increments from 0:00 rather than decrementing from a configured half-length.
- **FR-002**: Users MUST be able to toggle between Countdown and Count-Up modes via Settings before a match starts.
- **FR-003**: The Count-Up / Countdown preference MUST be persisted across app restarts.
- **FR-004**: When in Count-Up mode, pause, resume, and all scoring, card, and menu actions MUST function identically to Countdown mode.
- **FR-005**: Sub-timers (conversion, penalty, kickoff) MUST continue to count down normally even when the main timer is in Count-Up mode.
- **FR-006**: Low-time alerts (30-second warning, zero-crossing vibration) MUST be suppressed when Count-Up mode is active.
- **FR-007**: The elapsed count-up time at the end of each half MUST be recorded in the event log.
- **FR-008**: The watch face MUST render the count-up value in the same large timer area used by the countdown, in M:SS format.
- **FR-009**: Switching from Count-Up to Countdown in Settings MUST restore the configured half-length on the watch face immediately (when game is idle).

### Key Entities

- **TimerMode**: A flag (Countdown / Count-Up) stored in settings; controls whether the main timer decrements `countdownRemaining` or increments `gameTime` for display.
- **GameElapsed**: The existing `gameTime` field already accumulates upward-elapsed seconds — Count-Up mode renders this value instead of `countdownRemaining`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A referee can configure Count-Up mode and start a match in under 30 seconds with no instructional aids.
- **SC-002**: The count-up timer is accurate to within 1 second of actual elapsed time over a 45-minute period.
- **SC-003**: Switching modes in Settings takes a single tap with immediate confirmation visible on the watch face.
- **SC-004**: All existing Countdown-mode features continue to work without regression when Count-Up mode is toggled off and back on.

## Assumptions

- Count-Up mode resets the upward elapsed display to 0:00 at the start of each half (consistent with how countdown resets to half-length at half-time).
- The existing `gameTime` field already increments during play; Count-Up rendering uses that field directly.
- No configurable count-up alarm (trigger at a specific elapsed time) is in scope for this feature.
