# Main-Screen UI Specification

## Purpose

This document is the canonical contract for the live match screen.

Its job is to remove ambiguity from layout work. A renderer change should be
reviewable against this document without relying on screenshots, memory, or
taste alone.

Scope for this version:

- live match screen only
- all supported device families
- visual hierarchy, band ownership, spacing priorities, and acceptance rules

Out of scope for this version:

- menus
- settings screens
- export/history views
- screenshot-golden workflow

## Device Families

The live match screen is specified by family, not by one-off per-device tuning.

- `compact_round`: 240x240-class round watches such as fēnix 6
- `large_round`: newer/larger round watches
- `rectangular`: vívoactive-style rectangular watches

Requirement:

- the app may tune layout by family
- the app must not rely on ad hoc per-device nudges unless a device is proven
  exceptional and the exception is documented separately

## Visual Priority

The main match screen uses this strict priority order:

1. Main countdown and scores are co-primary
2. Match state text is secondary
3. Team identity labels are required support for the score columns
4. Elapsed timer, half text, and tries text are tertiary metadata
5. Card rows are important but subordinate to the primary lanes
6. Idle hints and status hints are low priority
7. Icons are lowest priority

Pass/fail interpretation:

- co-primary means countdown readability and score readability must both be
  preserved
- lower-priority content must compress before primary content is allowed to
  degrade

## Screen Bands

The live match screen is divided into three measured bands.

### Header band

Required rows:

- elapsed timer row
- `HOME` / `AWAY` row
- score row
- center metadata row(s) below the score band

Requirements:

- `HOME` stays above the left score column
- `AWAY` stays above the right score column
- team labels must stay inside the safe top band
- score digits must never overlap any center metadata
- center metadata must never sit inside the score digits
- header spacing must be measured from actual font heights and safe content
  bounds, not raw screen-height percentages alone

### Main content band

Required content:

- card rows
- main countdown

Requirements:

- the countdown remains centered and visually dominant
- card rows anchor beneath their respective team columns
- card rows may push the countdown downward only when visible card-row count and
  measured spacing require it
- countdown placement must come from measured band boundaries, not incidental
  state-label appearance
- the countdown must never overlap cards

### Lower band

Required content:

- state text such as `PAUSED`, `HALF TIME`, `GAME ENDED`
- idle hints
- locked hint

Requirements:

- idle, playing, and paused must reserve a compatible lower-band contract
- state text appearing or disappearing must not change countdown Y by itself
- hint visibility may vary by state, but the layout contract used for countdown
  anchoring must remain stable

## Tight-Space Compression Order

When space becomes tight, the screen must degrade in this order:

1. Compress low-priority spacing
2. Compress metadata spacing and metadata placement
3. Compress card-row breathing room if still safe
4. Preserve both countdown readability and score readability

Forbidden interpretations:

- do not protect scores first at the expense of the countdown
- do not protect the countdown first at the expense of scores
- do not solve tight space by letting metadata drift into the score row

Balanced-compromise rule:

- scores and countdown are both protected lanes
- tertiary metadata yields before either primary lane is allowed to degrade

## Scoreboard Contract

Requirements:

- left score column is always `HOME`
- right score column is always `AWAY`
- full `HOME` / `AWAY` wording is required for this version
- score digits are white
- `HOME` label is blue
- `AWAY` label is yellow
- team labels must remain less visually dominant than the score digits
- score columns must stay recognizable even when the center countdown reads
  large pre-start values such as `40:00` or `10:00`
- the score lane must remain visually separate from `Half` and tries metadata

Review-blocking failures:

- score digits overlap metadata
- team labels clip into the bezel
- team ownership becomes ambiguous at a glance

## Countdown Contract

Requirements:

- the countdown is visually dominant
- the countdown must remain fully visible inside the safe content area
- the countdown must not shift vertically when:
  - idle becomes playing
  - playing becomes paused
  - paused becomes playing
- the countdown may move only when visible card-row count changes and the
  measured layout genuinely requires extra space

Review-blocking failures:

- countdown overlaps header content
- countdown overlaps cards
- countdown overlaps the lower band
- pause/resume changes countdown Y without a card-row-count change

## Card Row Contract

Requirements:

- only the first two active sanctions per team are shown at once
- rows use split fields
  - label token such as `Y1` / `R1`
  - timer or status such as `9:59` / `PERM`
- timer/status text must not be smaller than the label token
- yellow rows use yellow text
- red rows use red text
- permanent red cards use `PERM`
- card rows must remain legible, but they are subordinate to the countdown and
  score lanes
- legibility should come from spacing, alignment, and color before decorative
  chrome is considered

Review-blocking failures:

- timer text is smaller than its label token
- card rows intrude into the score lane
- card rows intrude into the main countdown lane

## State Contracts

### Idle

Must communicate:

- selected starting half duration
- team ownership
- how to adjust the timer
- how to start

Requirements:

- idle hints remain readable
- idle hints do not overlap the countdown
- idle adjustments feel immediate on hardware

### Playing

Must communicate:

- countdown
- score
- elapsed timer
- visible sanctions

Requirements:

- no instructional hint may displace the countdown
- the layout must remain visually stable as timers update

### Paused

Must communicate:

- pause state clearly

Requirements:

- `PAUSED` is visually obvious
- showing `PAUSED` must not shift the countdown relative to the equivalent
  playing state
- active card rows must not create a separate paused-only countdown jump

### Overlay states

Includes:

- conversion overlay
- penalty overlay

Requirements:

- the main countdown remains visible
- the special timer/message may take temporary emphasis
- overlay rendering must not redefine the underlying main-screen layout
  contract

## Cross-Device Rules

Requirements:

- round families reserve more top and side safe area than rectangular layouts
- rectangular layouts may use more width but must preserve the same hierarchy
- the same state should feel recognizably the same across all families
- family adaptation is allowed; family-specific meaning changes are not

## Non-Negotiable Invariants

Any of the following is a review-blocking defect:

- score digits overlap metadata
- countdown overlaps header, cards, or lower-band content
- `HOME` / `AWAY` clip into the bezel
- center metadata appears inside the score digits
- pause/resume changes countdown Y without a card-row-count change
- card timer typography drops below label size
- important text renders outside the safe visible area

## Manual Acceptance Checklist

The following states must be checked on at least one device from each family.

### Idle

1. Idle with no cards

### Playing

2. Playing with no cards
3. Playing with one visible card
4. Playing with two visible cards on one side

### Paused

5. Paused with no cards
6. Paused with one visible card

### Other states

7. Halftime
8. Conversion or penalty overlay

Required family coverage:

- `compact_round`
- `large_round`
- `rectangular`

## Test Mapping Expectations

This spec is intended to map cleanly to renderer regressions.

Minimum regression categories:

- stable countdown anchor across idle/playing/paused
- safe header bounds
- metadata below the score band
- card timer typography floor

If the implementation cannot be validated against those categories, the spec is
still too vague.

## Change Policy

Any change to the main match screen must update this document if it changes:

- visual priority
- band ownership
- safe-area rules
- typography floors
- state-specific layout guarantees
- acceptance expectations

If a proposed UI change cannot be explained clearly in this document, it is too
ambiguous to be considered complete.
