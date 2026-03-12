# Feature Specification: Multi-Match Session Mode

**Feature Branch**: `003-multi-match-session`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Multi-match session mode — Run N consecutive matches with automatic reset between them; show a running session score log."

## Background & Problem Statement

Tournament referees routinely officiate 4–8 matches back-to-back in a single day. After each game ends they must manually reset the app, reconfigure the game type and timer, and lose access to the previous match’s scoreline unless they wrote it down. Adding a session mode that automatically resets for the next match while preserving a running score log means the referee leaves the tournament with a complete record of every game they managed — directly on their watch, no notebook required.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automatic Reset and Session Log After Each Match (Priority: P1)

A referee is working a 7s tournament pool stage with 5 matches. After the final whistle of the first match the watch shows the final score and the referee selects "Next Match". The app resets to idle (with the same game type and timer configuration), and the previous match's final score is saved to a session log entry. After 5 matches the referee can scroll through a session log showing all 5 scores with match numbers.

**Why this priority**: This is the complete feature in its simplest form. One story — auto-reset with a session log entry written after each game — delivers the entire value for tournament referees. Everything else is configuration and polish on top.

**Independent Test**: Play two complete matches back-to-back using the "Next Game" prompt. After the second match, open the session log and confirm both match scorelines are listed with match numbers and timestamps.

**Acceptance Scenarios**:

1. **Given** a match has ended, **When** the referee is on the end-game screen, **Then** a "Next Match" option is visible alongside the existing menu options.
2. **Given** the referee selects "Next Match", **When** confirmed, **Then** scores reset to 0–0, the half resets to 1st Half, the timer resets to the configured half-length, and the app enters STATE_IDLE — the referee must press start to begin the new match.
3. **Given** the "Next Match" action was taken, **When** the referee views the session log, **Then** the previous match's final score (e.g. "M1 (7s): 21 – 14") appears as a log entry including the game type.
4. **Given** 5 matches have been played in a session, **When** the session log is opened, **Then** all 5 match entries are listed in order.

---

### User Story 2 - View and Navigate Session Log (Priority: P2)

After the final match of the tournament pool the referee wants to confirm the results. They open the session log from the main menu and scroll through all 5 entries, each showing match number, home score, and away score. The list is accessible any time — not just at game-end.

**Why this priority**: Accessibility of the log at any time (not just end-of-match) is what makes the feature useful for verification and reporting. Without on-demand access, referees would need to memorise or write down results between matches anyway.

**Independent Test**: Play 3 matches, then open the Session Log from the main menu mid-fourth match. Confirm the 3 completed matches are listed with correct scores.

**Acceptance Scenarios**:

1. **Given** the referee opens the main menu, **When** the session log option is selected, **Then** a scrollable list of all completed matches in the current session is shown.
2. **Given** the session log is open, **When** the referee scrolls, **Then** each entry shows match number, game type, final score (e.g. "M2 (15s): 7 – 7"), and the match start time.
3. **Given** no matches have been completed yet (e.g. first match in progress), **When** the session log is opened, **Then** a "No matches completed" placeholder message is shown.

---

### User Story 3 - Configure and Reset Session (Priority: P3)

At the start of a new tournament day the referee wants to clear the session log from yesterday’s matches and start fresh. In Settings → Session they select "Clear Session" and confirm. The session log is emptied and the match counter resets to M1.

**Why this priority**: Session management is the least critical capability — an old session log is an inconvenience, not a blocking problem. Referees can always scroll past old entries. Explicit clear is a quality-of-life feature.

**Independent Test**: Play 2 matches, clear the session, then play another match. Confirm the log shows only 1 entry labelled "M1" (not M3).

**Acceptance Scenarios**:

1. **Given** a session has entries from previous matches, **When** the referee selects "Clear Session" in Settings, **Then** the session log is emptied and the match counter resets immediately (no additional confirmation step).
2. **Given** a session clear has been performed, **When** the next match is completed, **Then** it is logged as "M1".
3. **Given** the referee cancels the clear confirmation, **When** they return to the session log, **Then** the existing entries are unchanged.

---

### Edge Cases

- What happens if the referee exits the app mid-session? The session log is persisted to Storage after each match completes; partial sessions survive app close and reopen.
- What happens if the session log fills up (many matches)? The log is capped at 20 entries; when a 21st entry is added the oldest is silently dropped — no truncation indicator is shown in the UI.
- What happens to the GPS track when "Next Match" is triggered? If GPS is currently recording, the active GPS session is finalised before match state resets. If GPS is not active (e.g. 017-gps-match-summary not installed or GPS disabled), the step is skipped entirely.
- What happens if "Next Match" is triggered but the referee decides to cancel? A "Cancel" option on the confirmation dialog returns to the end-game screen without resetting anything.
- What happens if team names are configured? Team names are **not** stored in session log entries in this feature — the log stores scores and game type only. Team name capture in the log is deferred to a future enhancement (013-team-name-entry integration).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After a match ends, the app MUST offer a "Next Match" option that resets all match state (scores, half number, card timers) to the start of 1st Half in STATE_IDLE, while preserving game type and timer configuration. The referee must explicitly press start to begin the new match.
- **FR-002**: When "Next Match" is confirmed, the final score of the completed match MUST be written to the session log before the reset occurs.
- **FR-003**: The session log MUST be accessible from the main menu at any time during or between matches.
- **FR-004**: Each session log entry MUST include: match number, game type (7s / 15s; 10s label requires 001-custom-half-timer to be merged), home score, away score, and match start timestamp.
- **FR-005**: The session log MUST be persisted to Storage and survive app restarts.
- **FR-006**: Users MUST be able to clear the session log and reset the match counter via Settings.
- **FR-007**: The session log MUST display a maximum of 20 entries; when a 21st entry is added the oldest is silently dropped with no UI notification.
- **FR-008**: If GPS recording is active at the time "Next Match" is confirmed, the current GPS activity session MUST be finalised before match state is reset. If GPS is not active, this step is skipped.

### Key Entities

- **Session**: A persisted list of completed match summaries for the current tournament day.
- **MatchRecord**: A single session log entry containing match number, game type, final scores, and start timestamp.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Transitioning from one match to the next (via "Next Match" prompt) takes under 10 seconds including confirmation.
- **SC-002**: The session log accurately reflects the final scores of all completed matches — zero discrepancies in 10 consecutive test matches.
- **SC-003**: The session log persists across an app restart — 100% persistence rate.
- **SC-004**: All existing single-match features continue to work without regression in session mode.

## Assumptions

- Session mode is always active; there is no separate "enable session mode" toggle. The "Next Match" option simply appears at game-end alongside existing options.
- Game type and timer settings carry over to the next match automatically; the referee does not need to re-configure them unless they want to change.
- Team names are not reset between matches — they persist in Settings as normal.
- Session log entries record the system clock time (wall clock) for the start timestamp, not the game clock.
- The session log is **never auto-reset** by date, app restart, or any automatic trigger. Only the explicit "Clear Session" action in Settings resets the log and match counter.

## Clarifications

### Session 2026-03-10

- Q: When does a new Session automatically start (or reset) without the referee explicitly using "Clear Session"? → A: Never auto-resets — only "Clear Session" in Settings resets the log and counter
- Q: When the session log reaches its 20-entry cap and an old entry is dropped, should there be a visible truncation indicator in the UI? → A: Drop silently — no truncation indicator anywhere
- Q: Should FR-008 (GPS session finalisation on "Next Match") be enforced unconditionally or only when GPS is active? → A: Conditional — only finalise GPS session if GPS recording is currently active
- Q: After "Next Match" is confirmed, what state does the app enter for the new match? → A: Auto-reset to 1st Half in STATE_IDLE — referee presses start to kick off
- Q: Should each session log entry include the game type alongside the scoreline? → A: Yes — include game type (e.g. "M2 (7s): 21 – 14")
