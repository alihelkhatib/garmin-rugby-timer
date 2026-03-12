# Feature Specification: Fully Customizable Half Timer

**Feature Branch**: `001-custom-half-timer`  
**Created**: 2026-03-10  
**Status**: Draft  
**Input**: User description: "Make the half-timer fully customizable — any minute value, not just presets"

## Background & Problem Statement

The rugby timer application previously offered only a fixed set of preset half-lengths (5, 7, 10, 12, 15, 20, 25, 30, 35, 40, 45 minutes). A user review highlighted that age-grade matches use non-standard durations (e.g. 6, 8, 18, 23, 27 minutes per half) that were missing from the list. The goal of this feature is to replace all preset menus with a free-form input mechanism so any whole-minute duration can be selected without developer intervention or an app update.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Set Custom Half Length at Game Start (Priority: P1)

A referee sets up a new match on their Garmin watch. They select their game type (7s or 15s) and are immediately presented with a duration picker that scrolls freely through any whole-minute value. They scroll to the exact half length their competition rules require — for example, 8 minutes for an U14 7s age-grade fixture — confirm, and the timer is ready with that duration.

**Why this priority**: This is the primary user journey blocked by the original limitation. Every match start goes through this path. Without it, age-grade referees cannot use the app at all for non-standard durations. Delivering this alone provides full value.

**Independent Test**: Can be fully tested by starting the app fresh, selecting a game type, entering an uncommon duration (e.g. 8 min or 23 min), confirming, and verifying the countdown reflects that exact value before a game has started.

**Acceptance Scenarios**:

1. **Given** the app is on the idle screen, **When** the user selects a game type, **Then** a duration input screen opens that allows any whole-minute value between 1 and 99 minutes to be selected.
2. **Given** the duration picker is open, **When** the user selects 8 minutes and confirms, **Then** the main countdown displays 8:00 and the stored half-length is 8 minutes.
3. **Given** the duration picker is open, **When** the user selects 23 minutes and confirms, **Then** the main countdown displays 23:00.
4. **Given** the duration picker is open, **When** the user presses back without confirming, **Then** the app returns to the game-type selection without changing the current timer value.

---

### User Story 2 - Change Half Length Between Matches via Settings (Priority: P2)

A referee has already run one match and wants to run a second with a different half length (e.g. switching from a 7-minute U12 game to a 10-minute U16 game). Between matches, while the app is idle, they navigate to Settings → Half Timer, adjust the duration freely, and the new value is used when they start the next game.

**Why this priority**: Referees often officiate back-to-back matches with different durations. Without a mid-session edit path, they must restart the app each time. This is high-value for multi-match use cases.

**Independent Test**: Can be fully tested by going to Settings → Half Timer while idle, entering a new value, returning to the watch face, and confirming the countdown reflects the updated duration.

**Acceptance Scenarios**:

1. **Given** the app is idle with a 7s game type active and a saved half-length of 7 minutes, **When** the user navigates to Settings → Half Timer and sets 18 minutes, **Then** the watch face countdown changes to 18:00 and `halfDuration7s` is updated to 18.
2. **Given** the current game type is 15s with a saved value of 40 minutes, **When** the user opens the settings half-timer picker, **Then** the picker opens scrolled to 40, not a default.
3. **Given** a match is in progress, **When** the user navigates to Settings, **Then** the Half Timer item is disabled and cannot be selected.

---

### User Story 3 - Duration Persists Across App Restarts (Priority: P3)

A referee sets a custom half-length, uses the app for a full match, then closes the watch app. When they reopen it before the next match, the previously chosen duration is preserved as the default, so they do not need to re-enter it.

**Why this priority**: Persistence eliminates repetitive input for referees who run multiple consecutive matches with the same duration. It is a quality-of-life improvement layered on top of the core feature.

**Independent Test**: Set a custom duration for a 7s game (e.g. 12 minutes), close and reopen the app, and verify the idle countdown shows 12:00 with no game-type selection required.

**Acceptance Scenarios**:

1. **Given** the user set 12 minutes as the half length for a 7s game in a previous session, **When** the app is reopened, **Then** the game type is restored to 7s, the duration picker pre-fills at 12 minutes, and the countdown shows 12:00 after confirmation.
2. **Given** the device is restarted, **When** the app loads, **Then** the last saved game type and its corresponding half-length are independently restored.
3. **Given** the user previously set 12 minutes for 7s and 40 minutes for 15s, **When** they alternate game types, **Then** each game type recalls its own saved duration independently.

---

### Edge Cases

- What happens when the user dials a value of 0 minutes (tens=0, units=0)? The system silently clamps the result to 1 minute on accept; no error is shown and no column restriction is applied during scrolling.
- What happens if the stored value in the device is corrupted or missing? The system must fall back to a sensible default (7 minutes for 7s, 40 minutes for 15s) without crashing.
- What value should the picker open at if no duration has ever been saved? The picker opens at the game-type default (7 or 40 minutes) so the common case requires no scrolling.
- What happens if no game type has ever been saved (`lastGameType` absent)? The system defaults to 7s on first launch.
- What happens once a match has started? The half-length is locked for the duration of the match; the Settings Half Timer entry is disabled until the game ends or is reset.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to set any whole-minute half-length between 1 and 99 minutes inclusive, without the available values being limited to a predetermined list.
- **FR-002**: The duration input MUST be accessible during the new-game setup flow (immediately after selecting game type).
- **FR-003**: The duration input MUST be accessible from the Settings screen when the app is idle (no game in progress). The Settings "Half Timer" entry sets the default duration that will be pre-filled on the next new-game setup. It MUST be disabled while a match is in progress.
- **FR-004**: The system MUST persist the chosen half-length per game type (7s and 15s each have their own stored value) so values survive app closure and device restart.
- **FR-010**: The system MUST persist the last-selected game type (`lastGameType`) so that on app launch the correct per-type duration is loaded and the Settings "Half Timer" item operates on the right game type without requiring the user to select a game type first.
- **FR-005**: The system MUST pre-populate the duration picker with the saved value for the current game type each time it is opened, so users see and confirm their last setting for that game type rather than a fixed default.
- **FR-006**: The system MUST enforce a minimum duration of 1 minute by clamping silently on accept: if the combined picker value is 00, it is treated as 01. No dynamic column restrictions are required.
- **FR-007**: If no duration has previously been saved for a given game type, the system MUST default to 7 minutes for a 7s game type and 40 minutes for a 15s game type. These are per-type fallbacks applied only when the corresponding storage key is absent.
- **FR-008**: Once a match starts, the chosen half-length is fixed for all halves of that match and MUST NOT be changeable via Settings until the game ends or is reset. Changing the default in Settings only affects the next new game.
- **FR-009**: The countdown shown on the watch face MUST update to reflect the newly chosen duration as soon as the user confirms a new value while the game is idle.

### Key Entities

- **Half Duration**: The length of one half in whole minutes. Range 1–99. Stored per game type (separate values for 7s and 15s), each independently overridable by the user. Storage keys: `halfDuration7s` and `halfDuration15s`.
- **Game Type**: 7s or 15s, which determines card-timeout rules and the default half duration. Chosen once per match at the start of the new-game setup flow. Determines which storage key is read/written for half duration. The most recently selected game type is persisted to storage key `lastGameType` and restored on app launch.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can select any whole-minute value from 1 to 99 minutes as their half length within 3 button presses from the game-type selection screen.
- **SC-002**: The watch face countdown immediately reflects the user's chosen duration after confirmation, with no manual refresh required.
- **SC-003**: A duration set in one session is shown correctly when the app is reopened, in 100% of tested restarts.
- **SC-004**: The app never crashes or displays a zero or negative timer value regardless of what duration value is entered or restored from storage.
- **SC-005**: Age-grade durations not previously available as presets (e.g. 6, 8, 18, 23 minutes) can be set in the same number of steps as standard durations were previously.

## Assumptions

- Whole-minute granularity is sufficient; sub-minute (seconds-level) half length input is out of scope.
- The upper bound of 99 minutes covers all realistic rugby match durations (including extra time scenarios).
- Game type (7s vs 15s) selection remains a separate step preceding duration selection; this feature does not merge those two flows.
- Yellow and red card timeout durations are unaffected by this feature and continue to be controlled by their own settings menus.

## Clarifications

### Session 2026-03-10

- Q: Should the half duration be stored as a single shared value or separately per game type (7s / 15s)? → A: Per-game-type keys — separate storage for 7s (`halfDuration7s`) and 15s (`halfDuration15s`); switching game type recalls the last value used for that type.
- Q: In Settings, which game type's duration does the "Half Timer" picker edit? → A: The currently active (most recently selected) game type only; no extra game-type selection step in Settings.
- Q: Can the half-length be changed once a match has started? → A: No — the duration set at game start is fixed for the entire match (both halves); the Settings Half Timer entry is disabled while a game is in progress.
- Q: How is the 0-minute floor enforced on the two-digit picker? → A: Silent clamp on accept — if both digits are 0 the result is treated as 1 minute; no dynamic column restrictions during scrolling.
- Q: Is the last-selected game type persisted across app restarts? → A: Yes — stored as `lastGameType`; restored on launch so the correct per-type duration loads without prompting the user.


