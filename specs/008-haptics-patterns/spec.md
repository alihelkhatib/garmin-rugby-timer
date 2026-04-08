# Feature Spec: Haptics Patterns

## Context
Specify the haptics patterns required by the product and when they should fire. Scope is limited to: lock-toggle, start, pause, resume, and expiry events (conversion/penalty/card expiry).

## Preconditions
- Tests should mock device haptics APIs and assert vibration invocations.

## Key behaviors
- Short confirmation vib on: start, pause, resume, and lock-toggle.
- Distinct expiry vib on: conversion expiry, penalty expiry, and card expiry (single longer pulse).
- Haptics must not spam — at most one haptic per user-visible event and not more than one per second.

## Acceptance scenarios
1) Start/Pause/Resume/Lock
- When user starts, pauses, resumes, or toggles lock
- Then a short confirmation vibration is emitted exactly once per action

2) Expiry events
- When a conversion/penalty/card timer expires
- Then a distinct longer vibration pattern is emitted once

## Mocks & instrumentation
- Mock Device.vibrate/Vibrator APIs and assert pattern/type and invocation counts under rapid event sequences.

## Files referenced
- source/RugbyTimerView.mc (vibe trigger calls)
- source/RugbyTimerTiming.mc
