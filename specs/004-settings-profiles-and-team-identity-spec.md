# Feature Specification: Settings, Profiles, And Team Identity

**Feature ID**: `SPEC-004`  
**Created**: 2026-04-07  
**Status**: Adopted  
**Scope**: Match presets, custom profile mutation, idle-only settings, halftime-break settings, and team-label customization.

## User Scenarios & Testing

### User Story 1 - Prepare a match quickly from the idle screen (Priority: P1)

A referee must be able to set half length and choose a match format before kickoff without entering a complex editing flow.

**Why this priority**: Pre-match setup speed is fundamental on watch hardware.

**Independent Test**: While idle, change half length with hardware buttons and change profile in Settings. Confirm the visible countdown and settings labels update immediately.

**Acceptance Scenarios**:

1. **Given** the app is idle, **When** the referee presses `UP` or `DOWN`, **Then** half duration changes in whole-minute steps and the large countdown updates immediately.
2. **Given** the app is idle, **When** the referee selects `Match Format`, **Then** the chosen 7s, 10s, 15s, or U19 preset becomes the active setup immediately after the menu closes.

---

### User Story 2 - Keep live-match settings safe (Priority: P1)

As a referee, I must not be able to accidentally change live-only-protected settings once the match has started.

**Why this priority**: This protects match integrity and avoids mid-game state corruption.

**Independent Test**: During a live match, open Settings and try to enter idle-only rows. Confirm no underlying setting changes and a visible warning appears on the main screen.

**Acceptance Scenarios**:

1. **Given** the match is live, **When** the referee selects `Match Format` or `Team Labels`, **Then** the selection is blocked and a short `Idle only` notice is shown.
2. **Given** the match is live, **When** the idle-only warning is raised, **Then** the settings stack closes first so the warning is visible instead of hidden behind the menu.

---

### User Story 3 - Keep custom tweaks persistent without losing known presets (Priority: P2)

As a referee, I need built-in presets for common variants, but I also need manual tweaks to persist as a clear custom configuration.

**Why this priority**: It is important for repeat usability, but it builds on the idle-setup flows above.

**Independent Test**: Start from a built-in preset, change a timing or team-label setting, restart the app, and confirm the custom profile and values persist.

**Acceptance Scenarios**:

1. **Given** a built-in profile is active, **When** the referee changes a mutable timing or label setting, **Then** the active profile becomes `Custom` and the edited values persist.
2. **Given** a custom profile is invalid at startup, **When** model initialization runs, **Then** the app falls back to a safe built-in baseline instead of booting with broken timing values.

## Edge Cases

- Devices may return submenu labels instead of stable item ids; settings resolution must still work.
- Idle half-duration tweaks from the main screen must not silently persist a custom profile unless the user enters a real profile-setting mutation path.
- Team labels must remain readable on small round-watch layouts, even if some modes require compact aliases or suppression in the score band.

## Requirements

### Functional Requirements

- **SET-001**: The system MUST provide built-in match presets for Rugby 7s, 10s, 15s, and U19.
- **SET-002**: The system MUST allow idle half duration to be adjusted directly from the main screen in one-minute steps.
- **SET-003**: Idle half-duration adjustment MUST clamp to a supported range of 1 to 99 minutes.
- **SET-004**: Idle half-duration adjustment MUST update the visible main countdown immediately.
- **SET-005**: Idle half-duration adjustment MUST stay local to the current idle setup session unless the user changes a persistent settings value.
- **SET-006**: Manual changes to persistent timing or team-label settings MUST promote the active preset to `Custom`.
- **SET-007**: `Match Format` and `Team Labels` MUST be idle-only settings.
- **SET-008**: The system MUST show a visible `Idle only` warning when a blocked live-match settings row is selected.
- **SET-009**: The settings root MUST rebuild from the live model after changes so row subtitles reflect the actual active state.
- **SET-010**: The settings flow MUST restore focus to the changed row after rebuilding the root menu.
- **SET-011**: The app MUST support a configurable halftime-break setting that controls the break countdown between halves.
- **SET-012**: The app MUST support preset-based team-label modes, including `Home/Away` and alternate label pairs suitable for watch input.
- **SET-013**: Team-label selections MUST persist through storage and be included in the custom profile payload.
- **SET-014**: Team labels MUST be applied to the main score area where space allows, event log wording, and finalized summary/output text.

### Key Entities

- **Match Profile**: A named bundle of timing and presentation defaults such as 7s, 10s, 15s, U19, or Custom.
- **Editable Settings**: User-configurable options such as half duration, halftime break, overlay toggles, lock-on-start, dim mode, and team labels.
- **Team Label Mode**: A preset pair of team names used for display and event descriptions.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A referee can prepare a normal match from the idle main screen and settings menu without entering text.
- **SC-002**: Attempted live edits of idle-only settings never change the underlying live configuration.
- **SC-003**: A custom timing or team-label tweak persists across restart and does not get overwritten by the previously selected built-in preset.
