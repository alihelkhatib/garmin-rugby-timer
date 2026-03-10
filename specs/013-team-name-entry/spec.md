# Feature Specification: Team Name Entry

**Feature Branch**: `013-team-name-entry`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Team name entry — 4-character home/away team labels stored in Settings, shown in the score UI and in the event log export for easier identification."

## Background & Problem Statement

The score display and event log currently use the labels "Home" and "Away" for both teams. When a referee exports the event log or reviews the match summary at the end of a game, there is no way to tell which team is which without outside context. Allowing the referee to enter short 4-character team names (e.g. "NZL", "ENG", "SALE", "Bath") makes match records immediately identifiable and eliminates post-match confusion when sharing or filing logs.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enter Team Names in Settings Before a Match (Priority: P1)

Before officiating a game between two clubs, a referee opens Settings → Teams and enters "HARE" for the home team and "NORT" for the away team. They return to the watch face. The score display now shows "HARE 0 – 0 NORT" instead of "Home 0 – 0 Away". The names persist for the next match until changed.

**Why this priority**: The core value is in the rename itself — without this first story, none of the downstream uses (UI, log) work. A single referee entering the names before kick-off and seeing them on the watch face delivers the full P1 value.

**Independent Test**: Open Settings, set home name to "HULL" and away name to "LEED", return to watch face, confirm the score display reads "HULL 0 – 0 LEED".

**Acceptance Scenarios**:

1. **Given** the referee opens Settings → Teams, **When** they enter "SALE" for Home and "BATH" for Away and confirm, **Then** the watch face score area shows "SALE 0 – 0 BATH".
2. **Given** team names are set, **When** the referee restarts the app, **Then** the names are restored and still shown on the watch face.
3. **Given** the referee leaves the Home name field blank, **When** they save, **Then** the Home label reverts to "Home" (the default).
4. **Given** a team name is entered with more than 4 characters, **When** the referee confirms, **Then** only the first 4 characters are stored and displayed.

---

### User Story 2 - Team Names in Event Log (Priority: P2)

After a match the referee exports the event log to their phone. Every entry that previously said "Home Try" or "Away Yellow Card" now reads "SALE Try" or "BATH Yellow Card". This makes the log directly usable for match reports without manual editing.

**Why this priority**: The log is the primary output referees share. Making it carry team names gives the feature its long-term value beyond the single match. It depends on P1 (names must be stored) but can be verified independently once name storage is working.

**Independent Test**: Set team names, play a match including a try and a card, export the event log, confirm all entries use team names not generic "Home"/"Away" labels.

**Acceptance Scenarios**:

1. **Given** home name is "HARE" and away name is "NORT", **When** a try is scored and the event log is exported, **Then** the try entry reads "HARE Try" and not "Home Try".
2. **Given** a yellow card was issued, **When** the event log is viewed, **Then** the card entry uses the team name label.

---

### User Story 3 - Clear / Reset Team Names to Default (Priority: P3)

Between matches referees who use generic "Home"/"Away" for informal games want to quickly clear both names back to the default without having to manually backspace. A "Clear Names" option in Settings → Teams resets both labels to blank, which the app displays as "Home" and "Away".

**Why this priority**: Clearing between uses is purely quality-of-life. The app is fully functional without it — the referee could manually clear each field — but it reduces friction for users who alternate between named and anonymous matches.

**Independent Test**: Set both team names, then use the Clear Names option, return to the watch face, and confirm the display shows "Home 0 – 0 Away".

**Acceptance Scenarios**:

1. **Given** both team names are set, **When** the referee selects "Clear Names" in Settings → Teams, **Then** both labels reset to the default ("Home" / "Away") immediately.
2. **Given** team names have been cleared, **When** the app is restarted, **Then** the defaults are still shown (names are not restored from a previous save).

---

### Edge Cases

- What happens if the user enters only spaces? Whitespace-only input is treated as blank; the default label is used.
- What happens with special characters or non-Latin glyphs? The input should accept only alphanumeric characters and common punctuation that the watch font can render; any unsupported characters are silently dropped.
- What happens if both team names are identical (e.g., "HARE" vs "HARE")? The app accepts it — distinguishing duplicate entries is the referee's responsibility; no validation error is shown.
- What happens to the event log if team names are changed mid-match? Already-written log entries keep the name that was active when they were recorded; new entries use the updated name.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to enter a home team name and an away team name, each up to 4 characters, via Settings → Teams.
- **FR-002**: Team names MUST be displayed in the score area of the watch face in place of the generic "Home" / "Away" labels.
- **FR-003**: Team names MUST be persisted across app restarts.
- **FR-004**: If a team name is blank or absent, the app MUST fall back to the generic "Home" or "Away" label.
- **FR-005**: All event log entries MUST use the team name labels active at the time of the event.
- **FR-006**: A mechanism MUST exist to clear both team names back to the default in a single action.
- **FR-007**: Input MUST be clamped to 4 characters maximum; excess characters are silently discarded.
- **FR-008**: The team name entry mechanism MUST be accessible from Settings and MUST NOT require a match to be in progress.

### Key Entities

- **TeamName**: A string of up to 4 characters stored per-slot (home, away); displayed wherever a team label is shown.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A referee can enter both team names and return to the match-ready watch face in under 60 seconds.
- **SC-002**: Every event log entry for a named match uses the configured team names — 0 occurrences of the generic "Home" or "Away" labels when names are set.
- **SC-003**: Team names survive app restart and device power cycle; 100% persistence rate.
- **SC-004**: Existing watch face layout accommodates 4-character team names without truncation or overlap with the score digits.

## Assumptions

- 4 characters is the maximum that fits comfortably in the score area without redesigning the layout; longer names are silently truncated on save.
- The watch's built-in text-entry picker (or a simple A–Z scroll picker per character) is used for input, consistent with how other watch-face apps handle name entry on the Fenix 6 display.
- Team names are global (not per-game-type or per-match) — they persist until explicitly changed by the referee.
