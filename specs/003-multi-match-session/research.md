# Research: Multi-Match Session Mode

**Feature**: `003-multi-match-session`
**Date**: 2026-03-10
**Status**: Complete — all unknowns resolved

---

## Decision 1: Session Log Storage Format

**Question**: Does `Application.Storage` support arrays of dictionaries as a single persisted value?

**Decision**: Yes. `Storage.setValue(key, value)` / `Storage.getValue(key)` in Connect IQ SDK 8.x accepts any Monkey C object, including `Array<Dictionary>`. The existing codebase already stores arrays of dicts (e.g., `yellowHomeTimes`, `yellowAwayTimes` in `saveState()`). Storing the entire session log as a single array under key `"sessionLog"` is idiomatic and consistent.

**Rationale**: Flat single-key storage avoids index-keyed iteration over dynamic storage slots (`"session_0"`, `"session_1"`, …), which would require housekeeping across restarts. One array read/write is O(1) Storage calls regardless of entry count.

**Alternatives considered**:
- Individual keys per match entry (`"session_0"` … `"session_19"`) — rejected: requires iterating unknown key set on load, fragile on clear.
- Separate `"sessionMatchCount"` integer key — retained: the match counter increments monotonically even when entries are dropped at the 20-cap. Storing it independently ensures correct numbering.

---

## Decision 2: End-Game "Next Match" Entry Point

**Question**: How does the app reach the "Next Match" action after `STATE_ENDED`?

**Decision**: The main watch face view (`RugbyTimerView`) has an input delegate. After `endGame()` sets `gameState = STATE_ENDED`, the renderer displays "GAME ENDED" text. No dedicated end-game menu exists in the current codebase. The cleanest insertion point is the main input delegate's `onSelect()` handler: when the game state is `STATE_ENDED`, pressing SELECT pushes a new `EndGameMenu` (similar to how the in-game menu is pushed during play).

**Rationale**: Consistent with existing UX pattern. Zero new touch points — same SELECT gesture the referee uses throughout the match.

**Alternatives considered**:
- Auto-pushing `EndGameMenu` immediately when `endGame()` is called — rejected: breaks the current flow where `endGame()` is called from a menu that then pops itself before the watch face is shown.
- Adding "Next Match" to the existing in-game menu — rejected: spec states the option appears at game-end, and the in-game menu is only reachable during active play.

---

## Decision 3: Match Start Timestamp (Wall Clock)

**Question**: `model.gameStartTime` is set via `System.getTimer()` (milliseconds since power-on), not a wall-clock time. How do we capture a wall-clock timestamp for the session log entry?

**Decision**: Add a new field `matchStartWallClock` (Number, Unix seconds) to `RugbyGameModel`. Set it in `startGame()` via `Time.now().value()`. Clear it in `resetGame()`. The session log entry reads from this field when `nextMatch()` is called.

**Rationale**: `Time.now().value()` gives Unix epoch seconds — the standard wall-clock format. `System.getTimer()` is a monotonic tick counter and cannot be converted to a readable clock time.

**Implementation note**: Requires `using Toybox.Time;` import in `RugbyGameModel.mc`.

---

## Decision 4: Session Log Rendering Pattern

**Question**: What is the best way to render a scrollable session log list on the watch face?

**Decision**: Reuse `WatchUi.Menu2` with one `WatchUi.MenuItem` per session log entry (label = score line, subtitle = timestamp). This matches the existing `EventLogMenu` pattern in `RugbyTimerEventLog.mc` and requires no custom drawing code.

**Rationale**: `Menu2` provides free scroll, focus, and back navigation for Fenix 6. Custom view drawing would require manual scroll state, font metrics, and clipping — unnecessary complexity for a list display.

---

## Decision 5: GPS Finalisation on "Next Match"

**Question**: Does "Next Match" need to explicitly finalise the GPS activity session?

**Decision**: No explicit GPS handling needed in the "Next Match" flow. `endGame()` — which is always called before the "Next Match" option becomes visible — already calls `stopRecording()`, which calls `session.stop(); session.save(); session = null;`. By the time the referee triggers "Next Match", GPS is already cleanly stopped. `resetGame()` (called inside `nextMatch()`) also calls `stopRecording()` which safely no-ops when `session` is null.

**Rationale**: FR-008 is inherently satisfied by the existing `endGame()` → `stopRecording()` flow. No conditional GPS check is needed in the session feature code.

---

## Decision 6: Game Type Label in Log Entries

**Question**: The `gameType` integer refactor (feature 001-custom-half-timer) has not yet been implemented. How should game type be captured in log entries?

**Decision**: For this implementation, derive the game type label from the existing `model.is7s` boolean: `is7s ? "7s" : "15s"`. Mark with a `// TODO(001)` comment so the 3-way mapping (`"7s"`, `"10s"`, `"15s"`) is added when 001-custom-half-timer is merged.

**Rationale**: Blocking on 002 would delay an otherwise independent feature. The label is a display string; updating it is a 1-line change when 002 lands.

---

## Module Responsibility Map

> Per Constitution I — each change must live in exactly one module's responsibility.

| Concern | Module |
|---------|--------|
| Session log read/write/clear (Storage) | `RugbyTimerPersistence.mc` (new static helpers) |
| `nextMatch()` orchestration, `matchStartWallClock` field | `RugbyGameModel.mc` |
| `EndGameMenu`, `EndGameDelegate`, `SessionLogMenu`, `SessionLogDelegate` | `RugbyTimerDelegate.mc` |
| New menu XML entries | `resources/menus/menu.xml` |
| New string table entries | `resources/strings/strings.xml` |

No new source file is warranted — all additions fit cleanly within existing module responsibilities.
