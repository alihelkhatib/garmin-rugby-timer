# Data Model: 002-custom-half-timer

**Generated**: 2026-03-10  
**Branch**: `002-custom-half-timer`

---

## Storage Schema

All persistence uses `Toybox.Application.Storage` (flat key-value store on-device). This table shows the complete set of keys touched by this feature.

| Storage Key | Type | New / Changed / Existing | Description |
|---|---|---|---|
| `rugby7s` | Boolean | Existing (unchanged) | Last selected game type. `true` = 7s, `false` = 15s. Also serves as `lastGameType`. |
| `halfDuration7s` | Number (seconds) | **New** | Last saved half duration for a 7s game, in seconds. Range: 60–5940 (1–99 min). |
| `halfDuration15s` | Number (seconds) | **New** | Last saved half duration for a 15s game, in seconds. Range: 60–5940 (1–99 min). |
| `countdownTimer` | Number (seconds) | Existing (read-only, deprecated write) | Legacy fallback key. Old installations write here. New code ONLY reads this as a fallback when the per-type key is absent. New code never writes this key. |

### Read Priority Chain (on app launch / `initialize()`)

```
is7s = Storage.getValue("rugby7s") ?? false
typeKey = is7s ? "halfDuration7s" : "halfDuration15s"
halfDuration = Storage.getValue(typeKey)
           ?? Storage.getValue("countdownTimer")   // legacy fallback
           ?? (is7s ? 420 : 2400)                  // type default
```

---

## Entity: Half Duration

| Attribute | Value |
|---|---|
| **Unit** | Whole minutes (stored as seconds = minutes × 60) |
| **Range** | 1–99 minutes (60–5940 seconds) |
| **Floor enforcement** | Silent clamp on picker accept: `values[0]*10 + values[1]` < 1 → use 1 |
| **Ceiling** | Physically unreachable with two 0–9 digit columns (max = 99) |
| **Default — 7s** | 420 s (7 min) when no value saved for `halfDuration7s` |
| **Default — 15s** | 2400 s (40 min) when no value saved for `halfDuration15s` |
| **Granularity** | Whole minutes only; sub-minute not supported |
| **Immutability during match** | Once `startGame()` is called, `halfDuration` is frozen until `resetGame()` or `endGame()` |

---

## Entity: Game Type

| Attribute | Value |
|---|---|
| **Values** | `true` (7s), `false` (15s) |
| **Storage key** | `rugby7s` (existing) |
| **Set by** | `setGameType(is7sFlag)` in `RugbyGameModel` |
| **Effect on duration** | Determines which per-type duration key is read; does **not** overwrite the duration |
| **Persistence** | Written on every `setGameType()` call; read on `initialize()` |

---

## In-Memory State Changes (`RugbyGameModel` fields)

| Field | Current behaviour | New behaviour |
|---|---|---|
| `is7s` | Set from `rugby7s` storage | Unchanged |
| `halfDuration` | Set from `rugby7s` + `countdownTimer` | Set from `rugby7s` + per-type key (with legacy fallback) |
| `countdownTimer` | Mirror of `halfDuration` after load | Unchanged (mirror of `halfDuration`); no longer written as a separate Storage key by new code |
| `countdownRemaining` | Reset to `countdownTimer` on `initialize()` and `startGame()` | Unchanged |

---

## Method Contracts

### `RugbyGameModel.initialize()`
```
Read: rugby7s → is7s
Read: halfDuration7s / halfDuration15s (per-type) → halfDuration, with legacy countdownTimer fallback
No new writes on init
```

### `RugbyGameModel.setGameType(is7sFlag)`
```
Write: rugby7s = is7sFlag
Read:  per-type key → load saved duration for the new game type
Set:   halfDuration = loaded; countdownTimer = halfDuration
Set:   countdownRemaining = countdownTimer   (if STATE_IDLE)
No longer writes countdownTimer to Storage
```

### `RugbyGameModel.setHalfDuration(seconds)`
```
Set:   halfDuration = seconds; countdownTimer = seconds
Write: halfDuration7s  (if is7s == true)
Write: halfDuration15s (if is7s == false)
Set:   countdownRemaining = seconds   (if STATE_IDLE)
No longer writes countdownTimer to Storage
```

### `TimerPickerDelegate.onAccept(values)`  _(RugbySettings.mc)_
```
Compute: minutes = values[0]*10 + values[1]; if < 1 → 1
Compute: seconds = minutes * 60
Write:  halfDuration7s or halfDuration15s (based on current Storage.getValue("rugby7s"))
Update: parent menu item sub-label
Update: model.countdownTimer + countdownRemaining  (if STATE_IDLE)
No longer writes countdownTimer to Storage
```

### `GameTypePromptDelegate.onSelect(item)`  _(RugbyTimerDelegate.mc)_
```
Read: per-type key from Storage → defaultMinutes (with legacy fallback and type-default fallback)
Push: MinutesPicker(defaultMinutes) + NewGameTimerPickerDelegate
Unchanged: NewGameTimerPickerDelegate.onAccept calls setGameType then setHalfDuration
```

### `RugbySettingsMenu.initialize()`  _(RugbySettings.mc)_
```
Existing: reads countdownTimer for initial sub-label → change to read per-type key (with fallback)
New:      pass {:enabled => (gameState == STATE_IDLE)} to Half Timer MenuItem constructor
```

---

## Validation Rules

| Rule | Enforced where |
|---|---|
| `minutes >= 1` | `NewGameTimerPickerDelegate.onAccept`, `TimerPickerDelegate.onAccept` |
| `minutes <= 99` | Physically unreachable (two 0–9 digit pickers) |
| Half Timer Settings disabled during match | `RugbySettingsMenu.initialize()` via `:enabled` option |
| Duration immutable once match starts | `setHalfDuration` not wired to any in-game flow; Settings item disabled |

---

## State Transitions (duration flow)

```
App launch
  └─ initialize()
       └─ load is7s from "rugby7s"
       └─ load halfDuration from per-type key (or fallback)
             │
    [idle screen]
             │
    User selects game type
       └─ GameTypePromptDelegate.onSelect()
             └─ read per-type saved duration → defaultMinutes
             └─ push MinutesPicker(defaultMinutes)
                   │
             User confirms
               └─ NewGameTimerPickerDelegate.onAccept()
                     └─ setGameType(is7s)  → writes "rugby7s"
                     └─ setHalfDuration(s) → writes per-type key
                             │
                      [back to idle, countdown = chosen duration]
                             │
                    User presses start
                      └─ startGame() → halfDuration frozen for this match
                             │
                  [match in progress — Settings "Half Timer" disabled]
                             │
                     endGame() / resetGame()
                      └─ gameState → STATE_IDLE
                      └─ Settings "Half Timer" re-enabled on next menu open
```
