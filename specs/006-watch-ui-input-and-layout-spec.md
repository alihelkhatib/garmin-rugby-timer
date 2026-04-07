# Feature Specification: Watch UI, Input, And Layout

**Feature ID**: `SPEC-006`  
**Created**: 2026-04-07  
**Status**: Adopted  
**Scope**: Hardware-button routing, overlay input contract, lock behavior, round-watch layout, hints, toasts, and prompt visibility.

## User Scenarios & Testing

### User Story 1 - Use the watch entirely from hardware buttons (Priority: P1)

A referee must be able to operate the app from physical buttons on Fenix-class hardware even when device families emit slightly different callback paths.

**Why this priority**: Hardware-driven usability is the core interaction model on the target devices.

**Independent Test**: Use idle setup, live play, overlays, and menus through button input paths that may arrive via both `onKey()` and higher-level behavior callbacks.

**Acceptance Scenarios**:

1. **Given** the app is idle, **When** the watch reports `UP` or `DOWN` through raw key callbacks, **Then** the half duration still increments or decrements correctly.
2. **Given** the app is in halftime, **When** the watch reports `UP` or `DOWN`, **Then** the halftime-break countdown adjusts correctly.
3. **Given** the app is in conversion or penalty overlay state, **When** overlay-mapped keys are pressed, **Then** only overlay actions run and unrelated page/menu flows remain blocked.

---

### User Story 2 - Keep prompts and warnings visible on the correct screen (Priority: P1)

As a referee, I need prompts like `Idle only` and runtime toasts to actually appear where I can see them, not behind menus or after the relevant moment has passed.

**Why this priority**: Hidden prompts create silent failures and user confusion.

**Independent Test**: Trigger an idle-only settings warning, a start-time recording notice, and an overlay-owned message. Confirm each appears on the intended screen and clears correctly.

**Acceptance Scenarios**:

1. **Given** a live-match idle-only settings row is selected, **When** the app blocks the action, **Then** the warning is visible on the main match screen.
2. **Given** a runtime toast is raised during a start or resume action, **When** the transition completes, **Then** the message appears immediately.
3. **Given** a special overlay closes, **When** overlay-only messages expire or the overlay is dismissed, **Then** those messages do not leak back onto the normal match screen later.

---

### User Story 3 - Preserve readable layout on round watches (Priority: P2)

As a user, I want the countdown, score band, hints, and overlays to stay readable on round Garmin devices without clipping or visible jumping.

**Why this priority**: Layout quality matters, but the button and prompt contracts are even more fundamental.

**Independent Test**: Verify the main timer, score band, hints, and overlays on compact round layouts before kickoff, after kickoff, during overlays, and with active sanctions.

**Acceptance Scenarios**:

1. **Given** the app transitions from idle to live play, **When** the main screen rerenders, **Then** the large countdown keeps the same vertical anchor instead of visibly jumping.
2. **Given** score labels are too wide for round-watch shoulders, **When** the top band renders, **Then** labels are compacted or suppressed instead of clipping.
3. **Given** the conversion or penalty overlay is active, **When** it renders, **Then** the main countdown remains visible at the top and the overlay prompts fit inside the safe display area.

## Edge Cases

- Some devices emit `UP` and `DOWN` through behavior callbacks, some through raw key events, and some through both; the app must behave correctly without double-applying actions.
- Overlay action callbacks may be duplicated across raw-key and behavior paths; overlay actions must be de-duplicated.
- Idle hints, halftime hints, and locked hints must not overlap the large countdown or drop into clipped bezel zones.

## Requirements

### Functional Requirements

- **UI-001**: The app MUST support full primary operation through physical buttons.
- **UI-002**: Idle and halftime minute adjustments MUST work whether the watch routes input through raw key callbacks or page callbacks.
- **UI-003**: Overlay action routing MUST be isolated from normal score/card/menu flows while a special overlay is active.
- **UI-004**: Duplicate overlay actions from multiple callback paths MUST be debounced so one physical press cannot trigger multiple logical overlay outcomes.
- **UI-005**: The main screen MUST expose state-specific hints for idle, playing, halftime, and locked modes.
- **UI-006**: Non-overlay toasts MUST render only when the screen is not currently owned by a special overlay or active halftime overlay.
- **UI-007**: Overlay-owned messages MUST clear when their overlay closes.
- **UI-008**: The `Idle only` warning MUST be shown on the visible main screen, not underneath the settings stack.
- **UI-009**: The large main countdown MUST keep a stable vertical anchor between idle and normal live-play layouts.
- **UI-010**: The score-band renderer MUST apply round-watch safe-area logic before drawing optional team labels.
- **UI-011**: The app MUST hide sanction rows during special overlays while preserving the underlying sanction timing model.
- **UI-012**: Lock state MUST block match-changing inputs while still allowing the app to remain readable.

### Key Entities

- **Behavior Delegate Contract**: The button-routing rules that map hardware events into match actions.
- **View Hint Mode**: The presentation mode that selects which bottom-screen hints should be visible.
- **Main Content Layout**: The measured vertical-band layout for countdown, state text, hints, and card rows on round-watch displays.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A user can execute the main idle, live, and overlay flows from device buttons without relying on touch or text entry.
- **SC-002**: Visible prompts appear on the intended screen at the time they matter.
- **SC-003**: The main countdown no longer visibly shifts position when the match starts.
