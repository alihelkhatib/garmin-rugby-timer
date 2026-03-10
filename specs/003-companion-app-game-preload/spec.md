# Feature Specification: Companion App Game Pre-load & Team Names

**Feature Branch**: `003-companion-app-game-preload`  
**Created**: 2026-03-10  
**Status**: Draft  
**Input**: User description: "implement ability for a companion app to be used to easily pre-load scheduled game information. This would need to incorporate ability to modify the names of the teams to make them more identifiable than the current implementation."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Team Names on Scoreboard (Priority: P1)

A referee arrives at a match between "Northampton Saints" and "Harlequins." Before starting the timer, they navigate to Settings on their Garmin watch and enter abbreviated team names (e.g., "NTH" and "HAR"). From then on, the scoreboard displays those names instead of "Home" and "Away," making it immediately obvious which score belongs to which team throughout the match.

**Why this priority**: Every other story builds on the watch app displaying team names. This is a self-contained, high-value improvement that is independent of any companion app.

**Independent Test**: Can be fully tested by setting team names via the on-watch Settings menu and confirming the scoreboard, event log entries, and end-of-game summary all reflect the custom names — delivering immediate value with no phone required.

**Acceptance Scenarios**:

1. **Given** no team names have been set, **When** the scoreboard is displayed, **Then** it shows "Home" and "Away" as the default labels.
2. **Given** a referee sets "NTH" as the home team name and "HAR" as the away team name via Settings, **When** the scoreboard is displayed, **Then** it shows "NTH" and "HAR" in place of "Home" and "Away."
3. **Given** team names have been set, **When** the referee resets team names to default via Settings, **Then** the scoreboard reverts to "Home" and "Away."
4. **Given** team names have been set and the watch app is closed and reopened, **When** the scoreboard is displayed, **Then** the previously saved team names are still shown (names are persisted).
5. **Given** a team name longer than the maximum displayable length is entered, **When** the name is saved, **Then** the system truncates the name to fit the display and shows the truncated version.

---

### User Story 2 - Companion App Game Pre-load (Priority: P2)

A club administrator or referee coordinator has several games scheduled for a tournament day. Using a companion mobile app (connected to the Garmin watch via Bluetooth through the Garmin Connect app), they build a list of upcoming fixtures — each including the two team names, game format (7s or 15s), and half duration. They send this game list to the watch before handing it to the on-field referee. On the watch, the referee selects the current fixture from the pre-loaded list and starts the timer; all settings and team names populate automatically.

**Why this priority**: Eliminates manual watch configuration at pitch-side, reduces errors and setup time, and is the primary motivation for the companion integration.

**Independent Test**: Can be fully tested by sending a fixture list from the companion app to an idle watch (no match in progress), selecting a fixture on the watch, and verifying the scoreboard, game type, and half timer all match the sent data — delivering standalone value without requiring Story 3.

**Acceptance Scenarios**:

1. **Given** the companion app is connected to the watch and a fixture list has been defined, **When** the organizer taps "Send to watch," **Then** the fixture list appears on the watch within 30 seconds.
2. **Given** a pre-loaded fixture list exists on the watch and no match is in progress, **When** the referee navigates to "Select Fixture," **Then** they see a scrollable list of the pre-loaded fixtures showing both team names and game format.
3. **Given** the referee selects a fixture from the list, **When** they confirm the selection, **Then** the watch automatically configures home/away team names, game type (7s/15s), and half duration to match the fixture data.
4. **Given** a match is already in progress, **When** the watch receives a new fixture list, **Then** the existing match is not disrupted and the new fixtures are queued for selection after the current match ends.
5. **Given** the watch is out of range or the phone is unavailable, **When** the referee tries to sync, **Then** a clear status message indicates the connection is unavailable and previously loaded fixtures remain accessible.

---

### User Story 3 - Fixture Management in Companion App (Priority: P3)

An administrator uses the companion app between matches to update a fixture (e.g., a team name was entered incorrectly) or add an extra match to the schedule. They edit the fixture in the app and re-send the updated list. The watch replaces the old schedule with the updated one.

**Why this priority**: Useful for real tournament conditions but dependent on Story 2 being complete. Incremental improvement over bulk send.

**Independent Test**: Can be fully tested by modifying a previously sent fixture in the companion app, re-sending it, and confirming the updated fixture data replaces the old entry on the watch.

**Acceptance Scenarios**:

1. **Given** a fixture list has previously been sent to the watch, **When** the organizer edits a team name in the companion app and re-sends, **Then** the watch shows the updated team name in the fixture list.
2. **Given** a fixture list exists in the companion app, **When** the organizer adds a new fixture and sends, **Then** the new fixture appears at the end of the watch's fixture list.
3. **Given** a fixture list exists in the companion app, **When** the organizer deletes a fixture and re-sends, **Then** that fixture no longer appears on the watch.

---

### Edge Cases

- What happens when team names contain special characters or numbers? Names should be stored and displayed as-is; only length is capped for display.
- How does the watch handle a fixture list arriving while a conversion or penalty overlay is active? The overlay must not be interrupted; data is buffered and applied after the overlay closes.
- What happens when the fixture list exceeds on-device storage limits? Only the most recent batch sent by the companion app is stored; older batches are overwritten.
- How does the system handle a team name of zero characters? The watch reverts to the default "Home" or "Away" for that slot.
- What if the companion app sends an invalid game format value? The watch falls back to the current persisted game type and shows a notification that the fixture contained unrecognised data.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The watch app MUST display custom home and away team names on the scoreboard wherever "Home" or "Away" currently appear (score display, event log entries, end-of-game summary).
- **FR-002**: Team names MUST be editable directly from the on-watch Settings menu without requiring a phone.
- **FR-003**: Team names MUST be persisted between app sessions using the same on-device storage mechanism as all other app settings.
- **FR-004**: Team names MUST default to "Home" and "Away" when no custom names have been set or after a reset.
- **FR-005**: Team name display MUST be truncated to a maximum of 6 characters on the scoreboard to ensure legibility; full names (up to 20 characters) are stored and used in event log exports.
- **FR-006**: The watch app MUST accept a structured game fixture payload sent from a companion mobile app, containing at minimum: home team name, away team name, game type (7s or 15s), and half duration in seconds.
- **FR-007**: The watch app MUST store a list of up to 10 pre-loaded fixtures and present them in a selectable list when no match is in progress.
- **FR-008**: Selecting a fixture from the pre-loaded list MUST automatically apply all fixture settings (team names, game type, half duration) to the watch app, replacing any previously manually configured values.
- **FR-009**: The companion app MUST provide a form to create, edit, and delete fixtures before sending the list to the watch.
- **FR-010**: The companion app MUST send the complete fixture list to the watch in a single operation; partial or incremental updates are not required.
- **FR-011**: A mid-match fixture push from the companion app MUST NOT interrupt an active match; incoming data MUST be held until the current match ends or the app is reset.
- **FR-012**: The watch app MUST display a notification or status indicator when a fixture list has been successfully received, or when a connection attempt fails.
- **FR-013**: Users MUST be able to reset team names to "Home" and "Away" from the Settings menu independently of the fixture list.

### Key Entities

- **Fixture**: A single scheduled game entry containing home team name, away team name, game format (7s or 15s), and half duration (seconds). Optionally includes a display label (e.g., "Pool A – Game 3") for the selection list.
- **Fixture List**: An ordered collection of up to 10 fixtures, stored on-device and sourced from the companion app. Replaced entirely on each sync.
- **Team Name**: A short identifier for a team (up to 20 characters stored; up to 6 characters shown on the scoreboard). Applies per-session and persists across watch restarts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A referee can identify both teams by name on the scoreboard at a glance — without needing to recall which side is designated "Home" or "Away."
- **SC-002**: A match organizer can pre-load a full day's fixture list (up to 10 games) via the companion app in under 2 minutes.
- **SC-003**: Data transfer from the companion app to the watch completes in under 30 seconds when the devices are paired and within Bluetooth range.
- **SC-004**: A referee can select a pre-loaded fixture and have the watch fully configured (team names, game type, timer) in under 15 seconds, requiring no additional manual input.
- **SC-005**: Team names entered via the companion app or on-watch Settings are still correct after the watch is powered off and on again.
- **SC-006**: No active match (running clock, overlay dialog, or card timer) is disrupted by a companion app sync event.

## Assumptions

- The companion app is a Garmin Connect IQ companion (phone-side) component using the standard Garmin phone-to-watch communication channel available to Connect IQ apps; no third-party backend or cloud service is required for message delivery.
- The Garmin Connect mobile app (acting as the host) is installed on the referee's or organizer's phone; direct Bluetooth pairing outside of Garmin Connect is out of scope.
- Team name character encoding is limited to ASCII-compatible characters; multi-byte Unicode rendering on the watch display is not guaranteed and is out of scope.
- The companion app UI targets both iOS and Android via the Garmin Connect IQ SDK companion app framework; native platform UI components will be used where available.
- A maximum of 10 fixtures per list is sufficient for typical tournament-day use; this limit may be revisited based on on-device memory constraints identified during implementation.
