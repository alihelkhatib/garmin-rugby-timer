# Spec Index

This directory contains the current guardrail specifications for the Garmin Rugby Timer.

The intent is to make future changes safer by documenting:

- the user-facing behavior that must be preserved
- the main acceptance scenarios for each feature area
- the non-goals and edge cases that should not drift silently
- the requirement ids referenced by [`tests/TEST_TRACEABILITY.md`](/Users/600171959/Desktop/DesktopProjects/garmin-rugby-timer/tests/TEST_TRACEABILITY.md)

## Current Spec Set

- [`001-core-match-lifecycle-spec.md`](/Users/600171959/Desktop/DesktopProjects/garmin-rugby-timer/specs/001-core-match-lifecycle-spec.md)
  Core match lifecycle, clock ownership, halftime flow, and haptics.
- [`002-scoring-and-special-timers-spec.md`](/Users/600171959/Desktop/DesktopProjects/garmin-rugby-timer/specs/002-scoring-and-special-timers-spec.md)
  Score entry, conversion flow, penalty timers, undo, and event-log expectations.
- [`003-discipline-and-card-management-spec.md`](/Users/600171959/Desktop/DesktopProjects/garmin-rugby-timer/specs/003-discipline-and-card-management-spec.md)
  Yellow/red card behavior, stacking, timing rules, and sanction-specific UX.
- [`004-settings-profiles-and-team-identity-spec.md`](/Users/600171959/Desktop/DesktopProjects/garmin-rugby-timer/specs/004-settings-profiles-and-team-identity-spec.md)
  Match presets, custom-profile promotion, idle-only editing, and team-label behavior.
- [`005-persistence-recording-and-runtime-notices-spec.md`](/Users/600171959/Desktop/DesktopProjects/garmin-rugby-timer/specs/005-persistence-recording-and-runtime-notices-spec.md)
  Autosave/resume rules, finalized summaries, strict rugby recording, and one-shot notices.
- [`006-watch-ui-input-and-layout-spec.md`](/Users/600171959/Desktop/DesktopProjects/garmin-rugby-timer/specs/006-watch-ui-input-and-layout-spec.md)
  Button contract, overlay input routing, round-watch layout constraints, and visible prompts.

## How To Use These Specs

- Treat these documents as the source-of-truth behavior contracts for user-facing changes.
- Update the relevant spec before or with any intentional behavior change.
- Update [`tests/TEST_TRACEABILITY.md`](/Users/600171959/Desktop/DesktopProjects/garmin-rugby-timer/tests/TEST_TRACEABILITY.md) whenever a requirement gains, loses, or changes automated coverage.
- If behavior changes intentionally, update the spec, tests, and [`docs/process/log.md`](/Users/600171959/Desktop/DesktopProjects/garmin-rugby-timer/docs/process/log.md) in the same change.

## Decomposition Principle

The specs are organized by stable product surfaces rather than individual commits:

- timing and state
- scoring and special timers
- discipline
- settings and identity
- persistence and recording
- watch UI and layout

That split is meant to reduce future LLM-driven drift by making each behavioral contract small enough to reason about, but broad enough to stay useful as the implementation evolves.
