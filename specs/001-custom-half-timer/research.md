# Research: 001-custom-half-timer

**Generated**: 2026-03-10  
**Branch**: `001-custom-half-timer`  
**Status**: Complete — all NEEDS CLARIFICATION items resolved

---

## 1. Storage Key Strategy

### Decision
Per-game-type storage keys (`halfDuration7s`, `halfDuration15s`) with backward-compatible fallback to the existing `countdownTimer` key.

### Rationale
The codebase already stores game type as a boolean under the key `rugby7s`. Adding two per-type duration keys follows the same flat-dictionary pattern used throughout `RugbyGameModel.initialize()`. A fallback to the legacy `countdownTimer` key prevents data loss on devices that already have a value saved.

### How it works
On `initialize()`:
```
1. Read is7s from Storage.getValue("rugby7s")  → already done (no change needed)
2. Choose type-specific key: typeKey = is7s ? "halfDuration7s" : "halfDuration15s"
3. Load savedDuration = Storage.getValue(typeKey)
4. If null → try legacy Storage.getValue("countdownTimer")
5. If still null → use type default (420 s for 7s, 2400 s for 15s)
```

### Alternatives considered
- **Single `countdownTimer` key** — Rejected: switching game type would silently overwrite the other type's last-used value. US3 scenario 3 (alternating types) would fail.
- **`lastGameType` as a new key** — The spec names this key explicitly, but `rugby7s` boolean already fulfils the same role. Mapping `lastGameType` → `rugby7s` avoids key duplication; spec key names are logical names, not binding Storage key names.

---

## 2. Settings "Half Timer" Disable During a Match

### Decision
The "Half Timer" `WatchUi.MenuItem` is rendered with `setEnabled(false)` when `gameState != STATE_IDLE` at the time the Settings menu is opened.

### Rationale
`RugbySettingsMenu` is a `WatchUi.Menu2` that builds its item list at `initialize()` time. The model's `gameState` is accessible via `Application.getApp().model.gameState`. Calling `item.setEnabled(false)` greys the item in the Connect IQ UI and prevents `onSelect` from firing. This is the standard CIQ pattern for conditional menu items.

### Alternatives considered
- **Guard inside `onSelect`** — Would allow the item to be tapped but silently do nothing; worse UX; no feedback to the user that editing is blocked. Rejected.
- **Omit the item entirely when in-game** — Dynamic menu length confuses users who expect consistent item positions. Rejected.

---

## 3. Per-Type Duration Pre-fill in New-Game Picker

### Decision
`GameTypePromptDelegate.onSelect()` reads the saved per-type duration from Storage before pushing `MinutesPicker`, so the picker opens at the last-used value for that game type.

### Rationale
Current code uses a hardcoded `defaultMinutes = is7s ? 7 : 40`. This ignores any custom value previously saved. Reading from Storage (with a fallback to the type default) satisfies FR-005 for the new-game flow.

### Implementation
```monkeyc
var typeKey = is7s ? "halfDuration7s" : "halfDuration15s";
var savedSecs = Storage.getValue(typeKey);
if (savedSecs == null) { savedSecs = Storage.getValue("countdownTimer"); }
var defaultMinutes = (savedSecs != null) ? (savedSecs / 60) : (is7s ? 7 : 40);
if (defaultMinutes < 1) { defaultMinutes = 1; }
```

### Alternatives considered
- **Keep hardcoded defaults** — Violates FR-005. Rejected.

---

## 4. setGameType() Behaviour Change

### Decision
`setGameType()` MUST NOT overwrite `countdownTimer` / `halfDuration` with the type default. Instead it loads from the per-type storage key (with fallback) and updates `halfDuration` and `countdownTimer` with the loaded value.

### Rationale
Current code (`countdownTimer = halfDuration; halfDuration = is7s ? 420 : 2400`) loses any custom duration set by the user every time a game type change occurs. The new flow separates "game type selection" from "duration assignment" — duration comes from storage for the selected type.

### Alternatives considered
- **Leave setGameType as-is and let NewGameTimerPickerDelegate override** — Works for the new-game flow but breaks Settings "Game Type" toggle (which calls setGameType directly without showing a picker). Rejected.

---

## 5. setHalfDuration() Write Target

### Decision
`setHalfDuration(seconds)` saves to the per-type key (`halfDuration7s` or `halfDuration15s` depending on `is7s`), not to the generic `countdownTimer` key.

### Rationale
Maintaining the generic `countdownTimer` write would undermine per-type separation. The per-type key is the canonical store; legacy code reading `countdownTimer` is covered by the fallback chain in `initialize()`.

---

## 6. WatchUi.Picker API — No Additional Research Needed

The `WatchUi.Picker` / `WatchUi.PickerFactory` / `WatchUi.PickerDelegate` pattern is already implemented in `DigitPickerFactory`, `MinutesPicker`, and `TimerPickerDelegate` in `RugbySettings.mc`. No new API capabilities are required.

---

## 7. Settings Menu Item Enable/Disable API

### Decision
Use `WatchUi.MenuItem` constructor `{:enabled => false}` (if building during `initialize()`) or `menuItem.setEnabled(false)` (post-construction). Since the menu item is constructed inside `RugbySettingsMenu.initialize()`, the `:enabled` option in the constructor dictionary is the cleanest approach.

### Rationale
Connect IQ SDK 3.2+ supports the `:enabled` property on `MenuItem`. The project targets SDK 8.3 (`connectiq-sdk-win-8.3.0`) so this is safe. Setting it at construction avoids the need for a separate item reference being stored just to call `setEnabled` later.

---

## Summary of All Resolved Unknowns

| Unknown | Resolution |
|---|---|
| Per-type vs shared storage | Per-type keys `halfDuration7s` / `halfDuration15s` |
| Legacy `countdownTimer` key | Kept as fallback in read chain; not written by new code |
| `lastGameType` key | Mapped to existing `rugby7s` boolean (no new key needed) |
| Settings disable during match | `:enabled => false` on `Half Timer` MenuItem constructor |
| Pre-fill in new-game picker | Read from per-type key in `GameTypePromptDelegate.onSelect()` |
| `setGameType()` behaviour | Load from per-type key instead of overwriting with type default |
| `setHalfDuration()` write target | Write to per-type key only |
| Picker 0→1 clamp | Already implemented; confirmed sufficient |
