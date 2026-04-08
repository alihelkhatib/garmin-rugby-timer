# UI Specification

## Purpose

This document defines the intended visual and interaction contract for the live
match UI. It exists to remove ambiguity from layout work, make future visual
changes easier to review, and give renderer changes a stable target across
supported Garmin watch families.

This spec is intentionally practical rather than aspirational. It describes the
current intended behavior for the app, especially the main match screen.

## Supported Device Families

- `compact_round`: 240x240-class round watches such as fēnix 6.
- `large_round`: larger round watches such as newer fēnix 7/8 variants.
- `rectangular`: vívoactive-style rectangular watches.

The app should optimize by family, not by one-off per-device nudges, unless a
specific device proves exceptional.

## Main Screen Goals

The main screen must optimize for quick referee use under time pressure.

Primary goals, in order:

1. The main countdown must always be readable at a glance.
2. Score ownership must be obvious with no need to infer left/right teams.
3. Match state changes must not cause distracting vertical jumps.
4. Active sanctions must be visible without overpowering the main countdown.
5. The layout must remain inside the safe visible area on round watches.

## Visual Hierarchy

From highest to lowest importance:

1. Main countdown
2. Scores
3. Match state text such as `PAUSED`
4. Team identity labels `HOME` / `AWAY`
5. Match metadata `elapsed timer`, `Half`, `tries`
6. Card timers
7. Idle hints
8. Icons such as play/pause and lock

If space becomes tight, lower-priority content must compress before higher-
priority content moves or overlaps.

## Main Screen Structure

The live match screen is divided into three measured bands:

### 1. Header band

Contains:

- elapsed match timer
- team labels
- score digits
- half text
- tries text

Rules:

- `HOME` and `AWAY` must remain above their respective score columns.
- Team labels must stay inside the safe top band on round watches.
- Score digits must never overlap the half/tries metadata.
- Half/tries metadata must sit below the score band, not inside the score row.
- Header spacing should be measured from font heights, not guessed from raw
  percentages alone.

### 2. Main content band

Contains:

- card timer rows
- main countdown

Rules:

- The countdown is centered and visually dominant.
- Card rows anchor under their respective team columns.
- Card rows may push the countdown downward when required, but only from the
  measured card/header relationship.
- The countdown must not overlap card rows.

### 3. Lower band

Contains:

- state text such as `PAUSED`, `HALF TIME`, `GAME ENDED`
- idle hint text
- locked hint text

Rules:

- Idle, playing, and paused must reserve compatible lower-band space so the main
  countdown does not shift when state text appears or disappears.
- Hints may disappear by state, but their reserved layout contract must remain
  stable where countdown anchoring depends on it.

## Scoreboard Rules

- Left score column is always `HOME`.
- Right score column is always `AWAY`.
- Score digits are always white.
- `HOME` uses blue.
- `AWAY` uses yellow.
- Team labels are informational and must never be more visually dominant than
  the score digits.
- Scores must remain readable even when the match is idle at `40:00`, `10:00`,
  or other large pre-start values in the center.

## Countdown Rules

- The countdown is the most important visual element on the screen.
- The countdown must not shift vertically when:
  - idle transitions to playing
  - playing transitions to paused
  - paused transitions back to playing
- The countdown may move only when the number of visible sanction rows changes
  and the measured layout genuinely requires more vertical space.
- The countdown must remain fully visible within the safe content area.

## Card Timer Rules

- Only the first two active sanctions per team are shown at once.
- Card rows use split fields:
  - label token such as `Y1` or `R1`
  - timer/status such as `9:59` or `PERM`
- Label and timer must use the same font tier at minimum.
- Timer text should not be rendered smaller than the label token.
- Yellow card rows use yellow text.
- Red card rows use red text.
- Permanent red cards use `PERM`.
- Card rows should improve scanability through spacing, alignment, and color
  rather than through decorative boxes.

## Icons

- Play/pause icon sits in the upper-left safe area.
- Lock icon sits in the upper-right safe area.
- Icons must not collide with team labels or elapsed timer.
- Icons are useful but lower priority than text content.

## Idle Screen Contract

The idle state must clearly communicate:

- selected starting half duration
- which score belongs to which team
- how to adjust the timer
- how to start

Rules:

- `UP/DOWN: +1/-1` and `SELECT: Start` must remain readable.
- Idle hints must not overlap the countdown.
- Idle setup changes must feel immediate on hardware.

## Playing Screen Contract

The playing state must prioritize:

- countdown
- score
- elapsed timer
- visible sanctions

Rules:

- No instructional hint should displace the countdown.
- The layout should feel stable even as the elapsed timer and card timers update.

## Paused Screen Contract

The paused state must communicate pause clearly without reflowing the screen.

Rules:

- `PAUSED` must be obvious.
- Showing `PAUSED` must not shift the main countdown relative to the same
  playing layout.
- Active card timers may remain visible and must not cause a separate paused-only
  countdown jump.

## Overlay Contract

Conversion and penalty overlays are special modes.

Rules:

- The main countdown remains visible.
- The special timer and message may take center emphasis.
- Overlay content must not permanently alter the underlying main-screen layout
  contract.

## Cross-Device Rules

- Use one layout strategy per family, not ad hoc per-screen offsets.
- Round devices should reserve more top and side safe area than rectangular
  devices.
- Rectangular devices may use more of the screen width, but must preserve the
  same information hierarchy.
- The same state should feel recognizably the same across all device families.

## Non-Negotiable Invariants

These are review-blocking failures:

- score digits overlap any other text
- countdown overlaps any other text
- `HOME` / `AWAY` clip into the bezel
- pause/resume changes countdown Y without a card-row-count change
- center metadata appears inside the score digits
- card timer text is smaller than its label token
- important text renders outside the safe visible area

## Manual Acceptance States

The following states should be checked on at least one device from each family:

1. Idle with no cards
2. Playing with no cards
3. Paused with no cards
4. Playing with one yellow card
5. Paused with one yellow card
6. Playing with two visible cards on one side
7. Halftime
8. Conversion overlay

## Change Policy

Any change to the main match UI should update this spec if it changes:

- visual hierarchy
- band ownership
- safe-area rules
- typography rules
- state-specific layout guarantees

If a change cannot be explained clearly in this document, the change is
probably still too ambiguous.
