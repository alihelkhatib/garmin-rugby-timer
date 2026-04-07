# Feature Specification: Discipline And Card Management

**Feature ID**: `SPEC-003`  
**Created**: 2026-04-07  
**Status**: Adopted  
**Scope**: Yellow cards, red cards, sanction timing, stacking, labels, halftime behavior, and card-related alerts.

## User Scenarios & Testing

### User Story 1 - Track multiple active sanctions per team (Priority: P1)

A referee must be able to issue multiple yellow or red cards to the same team and still see the active timers in a predictable order.

**Why this priority**: Discipline tracking is a core differentiator for the app and must remain trustworthy under repeated use.

**Independent Test**: Issue multiple cards to the same team and verify stacking order, numbering, remaining time updates, and totals.

**Acceptance Scenarios**:

1. **Given** one active yellow card exists for a team, **When** a second yellow card is issued to that same team, **Then** the second timer appears beneath the first and receives the next label.
2. **Given** a team has both yellow and red active sanctions, **When** the sanction list renders, **Then** label numbering remains per-team and per-card-color.

---

### User Story 2 - Apply the correct law variant for 7s vs non-7s (Priority: P1)

As a referee, I need the sanction durations and red-card semantics to follow the selected format family.

**Why this priority**: Wrong sanction timing changes the meaning of the app during live play.

**Independent Test**: Issue yellow and red cards under 7s and non-7s profiles and verify durations and permanent-red behavior.

**Acceptance Scenarios**:

1. **Given** the active format is 7s, **When** a yellow card is issued, **Then** the timer duration is two minutes.
2. **Given** the active format is 7s, **When** a red card is issued, **Then** the red is permanent and no timed red replacement window is used.
3. **Given** the active format is not 7s, **When** a yellow or red card is issued, **Then** the yellow uses ten minutes and the timed red uses twenty minutes.

---

### User Story 3 - Keep sanction timing aligned with match stoppages (Priority: P2)

As a referee, I need card timers to pause and resume in sync with the match, while still continuing through halftime dead time as intended by the app’s rules.

**Why this priority**: It is behaviorally important but depends on the base discipline and timing model already working.

**Independent Test**: Add cards during play and while paused, then move through halftime and confirm the sanction timers follow the documented timing rules.

**Acceptance Scenarios**:

1. **Given** the match is paused, **When** sanction timers are visible, **Then** they stop decreasing until play resumes.
2. **Given** the app is in halftime, **When** sanction timers are active, **Then** they continue through the halftime period according to the shared suspension clock rules.

## Edge Cases

- Cards issued while the match is already paused must not create a visible one-second skew after play resumes.
- More than two active sanctions per team may exist; hidden ones must keep counting in the background and become visible as earlier timers expire.
- Overlay screens may hide card rows visually, but underlying sanction timing must continue according to state rules.

## Requirements

### Functional Requirements

- **CARD-001**: Users MUST be able to issue yellow and red cards to either team.
- **CARD-002**: Issuing a card MUST update the team’s cumulative card totals.
- **CARD-003**: Active sanctions MUST be labeled sequentially per team and per sanction color.
- **CARD-004**: Multiple active sanctions for one team MUST preserve issue order in the rendered stack.
- **CARD-005**: The sanction timer model MUST run from the shared `suspensionTime` clock rather than from independent wall-clock drift.
- **CARD-006**: Under 7s rules, yellow cards MUST last two minutes.
- **CARD-007**: Under non-7s rules, yellow cards MUST last ten minutes.
- **CARD-008**: Under 7s rules, red cards MUST be permanent.
- **CARD-009**: Under non-7s rules, red cards MUST create a timed twenty-minute replacement window.
- **CARD-010**: Card timers MUST pause during paused match state and resume without losing synchronization.
- **CARD-011**: Card timers MUST continue through halftime in line with the project’s sanction-clock contract.
- **CARD-012**: The renderer MUST display at most the first two active sanctions per team at once, while hidden sanctions continue counting in the model.
- **CARD-013**: Yellow card warning and expiry haptics MUST fire from sanction-clock events rather than from unrelated UI state.

### Key Entities

- **Card Entry**: A timed or permanent sanction with label, duration, start reference, and remaining time.
- **Sanction Totals**: Aggregate yellow/red counts per team used in summaries and persistence.
- **Suspension Clock**: The pauseable discipline clock that drives sanction updates.

## Success Criteria

### Measurable Outcomes

- **SC-001**: The same sanction stack restores with correct labels and positive remaining time after persistence/restart.
- **SC-002**: 7s and non-7s sanction rules produce different durations exactly where intended and nowhere else.
- **SC-003**: Card countdowns do not visually drift away from the main timer after pause/resume cycles.
