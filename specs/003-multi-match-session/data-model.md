# Data Model: Multi-Match Session Mode

**Feature**: `003-multi-match-session`
**Date**: 2026-03-10

---

## New Persistent Entities

### SessionLog

Stored at `Storage` key `"sessionLog"` as `Array<Dictionary>`.

| Field | Type | Description |
|-------|------|-------------|
| `"matchNum"` | Number | Sequential match number (1-based, monotonically incrementing) |
| `"gameType"` | String | `"7s"` or `"15s"` (updated to `"10s"` when 001-custom-half-timer lands) |
| `"homeScore"` | Number | Final home score at the moment "Next Match" was confirmed |
| `"awayScore"` | Number | Final away score at the moment "Next Match" was confirmed |
| `"startTimeSec"` | Number | Unix epoch seconds (`Time.now().value()`) captured when `startGame()` was first called |

**Capacity**: Maximum 20 entries. When a 21st entry is appended the oldest (index 0) is silently dropped.

**Persistence**: Survives app close, restart, and SDK updates. Cleared only by explicit "Clear Session" user action.

---

### SessionMatchCount

Stored at `Storage` key `"sessionMatchCount"` as `Number`.

| Field | Type | Description |
|-------|------|-------------|
| `"sessionMatchCount"` | Number | The next match number to assign. Starts at 1, increments after each `nextMatch()` call. Never decremented by the 20-entry cap — entries may be dropped while the counter keeps growing. |

**Reset**: Set to `1` by `clearSession()`.

---

## Model Field Changes

### `RugbyGameModel` — new field

| Field | Type | Set | Cleared |
|-------|------|-----|---------|
| `matchStartWallClock` | Number (Unix seconds) | `startGame()` via `Time.now().value()` | `resetGame()` (→ `null`) |

---

## State Transitions

```
STATE_ENDED
    │
    └─ SELECT pressed
         │
         └─ EndGameMenu pushed
              │
              ├─ :next_match selected
              │     │
              │     └─ nextMatch() called
              │          ├─ appendSessionEntry() → Storage["sessionLog"] updated
              │          ├─ Storage["sessionMatchCount"] incremented
              │          └─ resetGame() → STATE_IDLE (1st Half, scores 0-0)
              │
              ├─ :view_session_log selected
              │     └─ SessionLogMenu pushed (read-only, scrollable)
              │
              ├─ :reset selected
              │     └─ model.resetGame() → STATE_IDLE (no log entry written)
              │
              └─ :exit selected
                    └─ System.exit()
```

---

## New Storage Keys Summary

| Key | Type | Owner | Notes |
|-----|------|-------|-------|
| `"sessionLog"` | `Array<Dictionary>` | `RugbyTimerPersistence` | Max 20 entries |
| `"sessionMatchCount"` | `Number` | `RugbyTimerPersistence` | Monotonic counter |

---

## Validation Rules

- `matchNum` ≥ 1 always.
- `homeScore` and `awayScore` are ≥ 0 (game model enforces non-negative scores).
- `startTimeSec` may be `null` if the match was ended without ever starting the clock; display as `"--:--"` in the log.
- On `loadSessionLog()`, if `"sessionLog"` returns `null`, return an empty `Array` — no crash.
- On `loadSessionLog()`, if `"sessionMatchCount"` returns `null`, return `1` — fresh session.
