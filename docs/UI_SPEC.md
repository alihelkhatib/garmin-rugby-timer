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
3. Card rows are important but subordinate to the primary lanes
4. Team identity labels are required support for the score columns
5. Elapsed timer and tries are tertiary metadata
6. Idle hints and status hints are low priority
7. Icons are lowest priority

Pass/fail interpretation:

- co-primary means countdown readability and score readability must both be
  preserved
- lower-priority content must compress before primary content is allowed to
  degrade
- state text outranks hints and icons
- card urgency outranks lower-priority metadata

## Screen Bands

The live match screen is divided into three measured bands.

### Header band

Required rows:

- elapsed timer row
- `HOME` / `AWAY` row
- score row
- tries positioned beside their respective score columns in lower-emphasis text

Requirements:

- the elapsed real-time timer remains gray
- the elapsed real-time timer stays above the score band; it may sit centered
  above the scores
- `HOME` stays above the left score column
- `AWAY` stays above the right score column
- team labels must stay inside the safe top band
- team labels are smaller support labels and should rely on color plus position
  more than text size for quick recognition
- score digits must never overlap tries or other metadata
- tries must remain beside their respective scores and must never sit inside the
  score digits
- header spacing must be measured from actual font heights and safe content
  bounds, not raw screen-height percentages alone

### Main content band

Required content:

- card rows
- main countdown

Requirements:

- the countdown remains centered and visually dominant
- the nearest-expiring timed sanction must remain visible on the main screen
- additional timed sanctions may be shown only when space safely allows
- permanent red dismissals are lower priority than timed-card visibility and may
  be hidden from the main screen if needed
- card rows anchor beneath their respective team columns
- card rows may push the countdown downward only when visible urgent-card
  content and measured spacing require it
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
4. Hide lowest-priority items before shrinking primary lanes
5. Preserve both countdown readability and score readability

Forbidden interpretations:

- do not protect scores first at the expense of the countdown
- do not protect the countdown first at the expense of scores
- do not solve tight space by letting metadata drift into the score row

Balanced-compromise rule:

- scores and countdown are both protected lanes
- tertiary metadata yields before either primary lane is allowed to degrade
- explicit hide order is:
  - icons first
  - then tries
  - then elapsed timer

Compact-round detail modes:

- `critical-only`: scores, countdown, urgent timed cards, and essential state
  text only
- `critical-plus-elapsed`: adds the gray elapsed timer above the score band
- `critical-plus-elapsed-half`: adds the half row below the score band
- `full-compact`: adds per-team tries beside the score columns only if safe
  space still remains

Compact-round recovery order:

- when no timed sanction is active and measured space returns, metadata comes
  back in this order:
  - elapsed timer
  - then half
  - then tries

## Scoreboard Contract

Requirements:

- left score column is always `HOME`
- right score column is always `AWAY`
- full `HOME` / `AWAY` wording is required for this version
- score digits are white
- `HOME` label is blue
- `AWAY` label is yellow
- team labels must remain less visually dominant than the score digits
- team labels should be smaller than the score digits
- score columns must stay recognizable even when the center countdown reads
  large pre-start values such as `40:00` or `10:00`
- tries belong to their respective score columns, beside the score in smaller
  text
- the score lane must remain visually separate from tries and all other metadata

Review-blocking failures:

- score digits overlap metadata
- tries collide with score digits
- team labels clip into the bezel
- team ownership becomes ambiguous at a glance

## Countdown Contract

Requirements:

- the countdown is visually dominant
- the countdown and scores remain the dominant readable lanes
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

- rows use split fields
  - label token such as `Y1` / `R1`
  - timer or status such as `9:59` / `PERM`
- the nearest-expiring timed sanction must remain visible whenever any timed
  sanction is active
- additional timed sanctions may be shown if safe space remains
- when a timed sanction is active on compact round, the renderer must drop to
  `critical-only` before shrinking the countdown or score lanes
- timer/status text must not be smaller than the label token
- yellow rows use yellow text
- red rows use red text
- permanent red cards use `PERM`
- card rows must remain legible, but they are subordinate to the countdown and
  score lanes
- legibility should come from spacing, alignment, and color before decorative
  chrome is considered
- permanent red dismissals are lower priority than timed sanctions on the main
  compact-round screen and may be omitted while timed sanctions are active

Review-blocking failures:

- the nearest-expiring timed sanction is hidden while a lower-priority sanction
  remains visible
- permanent red presentation outranks an urgent timed sanction
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
- the elapsed timer remains gray and above the score band

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
- tries beside scores collide with score digits
- the nearest-expiring timed sanction is not visible while a timed sanction is
  active
- a permanent red marker outranks an urgent timed sanction
- important text renders outside the safe visible area

## Manual Acceptance Checklist

The following states must be checked on at least one device from each family.

### Idle

1. Idle with no cards

### Playing

2. Playing with no cards
3. Playing with one timed card
4. Playing with multiple timed cards so urgency visibility can be checked
5. Playing with a permanent red plus a timed card

### Paused

6. Paused with no cards
7. Paused with one timed card

### Other states

8. Halftime
9. Conversion or penalty overlay

Required family coverage:

- `compact_round`
- `large_round`
- `rectangular`

## Test Mapping Expectations

This spec is intended to map cleanly to renderer regressions.

Minimum regression categories:

- stable countdown anchor across idle/playing/paused
- safe header bounds
- tries adjacent to score columns without entering the score digits
- card timer typography floor
- nearest-expiring timed sanction visibility
- low-priority hide order under compact-round pressure

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
