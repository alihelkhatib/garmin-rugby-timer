# Feature Specification: Persistence, Recording, And Runtime Notices

**Feature ID**: `SPEC-005`  
**Created**: 2026-04-07  
**Status**: Adopted  
**Scope**: Match snapshot persistence, paused restore, finalized output, strict rugby recording, and one-shot runtime notice behavior.

## User Scenarios & Testing

### User Story 1 - Resume a match safely after leaving the app (Priority: P1)

A referee must be able to reopen an interrupted live match without the app resuming clocks in the background or restoring invalid pre-match junk as if it were a live session.

**Why this priority**: Safe restore is essential for trust in a real match environment.

**Independent Test**: Start a match, persist it, recreate the model, and verify the app restores to a paused resumable state. Also verify broken snapshots are cleared back to idle.

**Acceptance Scenarios**:

1. **Given** a live match is persisted, **When** the app restarts, **Then** the match restores as a paused snapshot with enough state to resume safely.
2. **Given** a malformed or blank saved snapshot exists, **When** startup validation runs, **Then** the snapshot is cleared and the app returns to idle with a short user-visible reset notice.

---

### User Story 2 - Keep persistence quiet during normal operation but explicit for operational issues (Priority: P1)

As a referee, I do not want noisy save-failure spam during normal match flow, but I do need actionable one-shot notices for important operational issues.

**Why this priority**: Runtime noise is disruptive during play, while silence on real failures is also unsafe.

**Independent Test**: Trigger a runtime notice path, confirm it is shown once, and verify generic autosave failure noise does not persistently surface during gameplay.

**Acceptance Scenarios**:

1. **Given** a runtime notice is raised, **When** the main view consumes it, **Then** the notice appears once and then clears.
2. **Given** a start/resume flow raises a recording notice, **When** the state transition finishes, **Then** the toast is flushed immediately instead of waiting for a later timer tick.

---

### User Story 3 - Respect the strict rugby-only recording contract (Priority: P2)

As a user, I want GPS/activity recording to start when supported, but if the device cannot record rugby, the match timer must still work without crashing or silently pretending recording succeeded.

**Why this priority**: Recording is useful but secondary to match timing.

**Independent Test**: Start a match in an environment with and without supported recording APIs and verify the app either opens a rugby session or reports a rugby-specific failure state.

**Acceptance Scenarios**:

1. **Given** rugby recording is supported, **When** the match starts or resumes into a recording-eligible state, **Then** a rugby activity session is opened or resumed.
2. **Given** rugby recording is unsupported or start fails, **When** the match starts, **Then** the match still runs and a short recording-specific notice is surfaced.

## Edge Cases

- Idle or ended states must clear stale saved live snapshots instead of writing a resumable match record.
- Persistence payloads must normalize score history, event log entries, and summary card arrays into Garmin-safe shapes before storage.
- If the app exits mid-match, the current recording segment must be stopped cleanly before process termination.

## Requirements

### Functional Requirements

- **PERSIST-001**: The app MUST persist in-progress live-match state in a resumable snapshot format.
- **PERSIST-002**: Persisted live matches MUST restore as paused snapshots rather than auto-resuming play.
- **PERSIST-003**: Idle and ended states MUST clear any stale live snapshot from the resumable save slot.
- **PERSIST-004**: Invalid or zero-duration saved snapshots MUST be discarded during startup and surfaced as a one-shot reset notice.
- **PERSIST-005**: Explicit scoring and discipline changes MUST write updated match state promptly rather than relying only on a delayed autosave window.
- **PERSIST-006**: Finalizing a match MUST write summary and event-log output suitable for later review/export.
- **PERSIST-007**: Storage payloads MUST be normalized to Garmin-safe primitive/container shapes before writing.
- **PERSIST-008**: Runtime notices MUST flow through a typed one-shot notice channel rather than through arbitrary raw strings.
- **PERSIST-009**: Toast-style runtime notices MUST be consumable exactly once.
- **PERSIST-010**: Start and resume flows MUST flush pending toast notices immediately when those notices are relevant to the new live state.
- **PERSIST-011**: The app MUST attempt activity recording using `SPORT_RUGBY` only.
- **PERSIST-012**: If rugby recording support is absent or recording start fails, the app MUST continue running the match and surface a short recording-specific notice.
- **PERSIST-013**: If the app stops while recording is active, the current recording segment MUST be stopped and saved cleanly.

### Key Entities

- **Persisted Match Snapshot**: The Garmin-safe representation of a resumable match.
- **Runtime Notice**: A typed, one-shot operational message intended for the watch UI.
- **Recording Session**: The active Garmin activity-recording handle for rugby-only match tracking.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A persisted live match can be restored and resumed without background time drift.
- **SC-002**: Invalid persisted data cannot strand the app outside a safe idle state.
- **SC-003**: Recording support failures are visible to the user but do not block timing, scoring, or match completion.
