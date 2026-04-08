# Feature Spec: Cards & Discipline Timers

## Context
Define sanctioned-card behavior: yellow and red cards, timed suspensions, permanent red behavior, UI presentation, and persistence across lifecycle.

## Preconditions
- App in playing or paused state. Tests should mock `RugbyTimerTiming` and `RugbyGameModel` to drive time and observe card state.

## Key behaviors
- Adding a Yellow/Red card records an event and (for timed sanctions) starts a suspension timer driven by `suspensionTime`.
- Timed suspensions follow different durations for 7s vs non-7s formats per rules.
- The renderer must always show the nearest-expiring timed sanction per team on the main screen when space is constrained.
- Red cards: for 7s, red is permanent (`PERM`); for 15s, red is a timed 20-minute sin bin (20:00). Timed red entries follow the same suspension timer model as yellow cards and persist into snapshots so remaining durations are restored on app restart.
- Active card timers persist into snapshots so restoring a live match preserves remaining durations.

## Acceptance scenarios
1) Yellow card starts timer
- Given match is playing
- When user issues a Yellow to HOME
- Then a timed sanction entry appears, a suspension timer starts, and an event is appended to the event log

2) Timer expiry
- Given a Yellow started at t=0
- When simulated time advances to expiry
- Then the sanction expires, an expiry event is logged, and UI updates to remove the timed row

3) Multiple cards: nearest-expiring visible
- Given multiple timed cards exist for HOME
- Then only the nearest-expiring appears on compact-round when space is tight; others exist in event log

4) Persistence across restart
- Given a live match with active card timers
- When the app is closed and reopened
- Then the restored snapshot contains remaining durations and UI shows correct remaining time

## Mocks & instrumentation
- Mock the timing loop (`RugbyTimerTiming.updateGame`) to advance time deterministically.
- Mock Storage to validate persisted card entries and snapshot shape.

## Files referenced
- source/RugbyTimerCards.mc
- source/RugbyTimerTiming.mc
- source/RugbyDisciplineService.mc
- source/RugbyTimerRenderer.mc
