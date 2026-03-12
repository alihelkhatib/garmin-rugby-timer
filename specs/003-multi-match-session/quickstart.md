# Quickstart: Multi-Match Session Mode

**Feature**: `003-multi-match-session`
**Date**: 2026-03-10

---

## What This Feature Adds

After a match ends, the referee can select "Next Match" to automatically save the final scoreline to a running session log and reset the app for the next game — preserving game type and timer settings. The session log is accessible from the main menu at any time and persists across app restarts.

---

## Files to Change

| File | Change Type | Summary |
|------|-------------|---------|
| `source/RugbyGameModel.mc` | Modify | Add `matchStartWallClock` field; add `using Toybox.Time`; set field in `startGame()`; clear in `resetGame()`; add `nextMatch()` method |
| `source/RugbyTimerPersistence.mc` | Modify | Add `appendSessionEntry()`, `loadSessionLog()`, `clearSession()` static helpers |
| `source/RugbyTimerDelegate.mc` | Modify | Add `EndGameMenu`, `EndGameDelegate`, `SessionLogMenu`, `SessionLogDelegate` classes; hook SELECT in STATE_ENDED on main delegate; add `:clear_session` in settings delegate |
| `resources/menus/menu.xml` | Modify | Add `EndGameMenu` XML block with 4 items; add `:view_session_log` to `MainMenu` |
| `resources/strings/strings.xml` | Modify | Add 6 new string IDs |

**No new source files.** All changes fit existing module responsibilities (Constitution I).

---

## Implementation Steps

### Step 1 — `RugbyGameModel.mc`

1. Add `using Toybox.Time;` at the top (after existing imports).
2. Declare `var matchStartWallClock;` alongside other fields.
3. In `startGame()`, after `gameStartTime = now;`, add:
   ```
   matchStartWallClock = Time.now().value();
   ```
4. In `resetGame()`, after `gameState = STATE_IDLE;`, add:
   ```
   matchStartWallClock = null;
   ```
5. Add `function nextMatch()`:
   ```
   function nextMatch() {
       // Build log entry from current match result
       var gameTypeLabel = is7s ? "7s" : "15s";  // TODO(002): update when gameType int lands
       var entry = {
           "matchNum"    => RugbyTimerPersistence.loadSessionMatchCount(),
           "gameType"    => gameTypeLabel,
           "homeScore"   => homeScore,
           "awayScore"   => awayScore,
           "startTimeSec" => matchStartWallClock
       };
       RugbyTimerPersistence.appendSessionEntry(entry);
       resetGame();
   }
   ```

### Step 2 — `RugbyTimerPersistence.mc`

Add three static helpers:

```
static function loadSessionLog() {
    var log = Storage.getValue("sessionLog");
    if (log == null) { log = []; }
    return log;
}

static function loadSessionMatchCount() {
    var count = Storage.getValue("sessionMatchCount");
    if (count == null) { count = 1; }
    return count;
}

static function appendSessionEntry(entry) {
    var log = loadSessionLog();
    log.add(entry);
    if (log.size() > 20) { log.remove(0); }  // silent drop, oldest first
    Storage.setValue("sessionLog", log);
    var next = loadSessionMatchCount() + 1;
    Storage.setValue("sessionMatchCount", next);
}

static function clearSession() {
    Storage.setValue("sessionLog", null);
    Storage.setValue("sessionMatchCount", 1);
}
```

### Step 3 — `RugbyTimerDelegate.mc`

Add four new classes at the end of the file:

**`EndGameMenu`** — `WatchUi.Menu2` with items: `:next_match`, `:view_session_log`, `:reset`, `:exit`.

**`EndGameDelegate`** — `WatchUi.Menu2InputDelegate`:
- `:next_match` → `model.nextMatch(); WatchUi.popView(SLIDE_DOWN)`
- `:view_session_log` → push `SessionLogMenu` / `SessionLogDelegate`
- `:reset` → `model.resetGame(); WatchUi.popView(SLIDE_DOWN)`
- `:exit` → `model.stopRecording(); System.exit()`

**`SessionLogMenu`** — `WatchUi.Menu2`, built from `RugbyTimerPersistence.loadSessionLog()`:
- Each entry → `MenuItem` with label `"M{n} ({type}): {h} – {a}"`, subtitle formatted time.
- If log is empty → single disabled item `"No matches yet"`.

**`SessionLogDelegate`** — `WatchUi.Menu2InputDelegate`:
- `onBack()` → `WatchUi.popView(SLIDE_DOWN)`

In the **main watch-face input delegate** (`RugbyTimerDelegate` or equivalent), find the `onSelect()` / `onKey()` handler and add:
```
if (model.gameState == STATE_ENDED) {
    WatchUi.pushView(new EndGameMenu(), new EndGameDelegate(model), WatchUi.SLIDE_UP);
    return true;
}
```

In the **settings delegate**, add handling for `:clear_session`:
```
} else if (item.getId() == :clear_session) {
    RugbyTimerPersistence.clearSession();
    WatchUi.popView(WatchUi.SLIDE_DOWN);
}
```

In the **main-menu delegate**, add handling for `:view_session_log`:
```
} else if (item.getId() == :view_session_log) {
    WatchUi.pushView(
        new SessionLogMenu(),
        new SessionLogDelegate(),
        WatchUi.SLIDE_UP
    );
    return;
}
```

### Step 4 — Resources

**`resources/menus/menu.xml`** — append new `EndGameMenu` and add to `MainMenu`:
```xml
<!-- Add to MainMenu -->
<menu-item id="view_session_log" label="Session Log" />

<!-- New menu -->
<menu id="EndGameMenu">
    <menu-item id="next_match"        label="Next Match" />
    <menu-item id="view_session_log"  label="View Session Log" />
    <menu-item id="reset"             label="Reset" />
    <menu-item id="exit"              label="Exit" />
</menu>
```

**`resources/strings/strings.xml`** — add:
```xml
<string id="EndGame_NextMatch">Next Match</string>
<string id="EndGame_SessionLog">Session Log</string>
<string id="EndGame_Reset">Reset</string>
<string id="Session_NoMatches">No matches yet</string>
<string id="Settings_ClearSession">Clear Session</string>
<string id="Session_Cleared">Session cleared</string>
```

---

## Manual Test Checklist

- [ ] Play two complete matches via "End Game" → "Next Match". Session log shows M1 and M2 with correct game type and scores.
- [ ] Open Session Log from the main menu mid-match — existing entries are shown; current match is not listed.
- [ ] Clear session via Settings → Clear Session. Confirm log shows "No matches yet". Play a new match and confirm it is logged as M1.
- [ ] Force-quit and reopen the app — session log entries survive.
- [ ] Play 21 matches (or simulate 21 entries). Confirm only 20 entries are retained, oldest dropped silently.
- [ ] Select "Next Match" then "Cancel" (back button) on the EndGameMenu — no entry is written and game remains in STATE_ENDED.
- [ ] Confirm all pre-existing flows (scoring, cards, GPS, event log export) continue to work without regression.

---

## Dependencies

| Dependency | Status | Impact |
|------------|--------|--------|
| 001-custom-half-timer (`gameType` integer) | Not yet merged | Game type label in log will show "7s" or "15s" only until 001 lands; 1-line TODO marked in `nextMatch()` |
| 017-gps-match-summary | Optional / independent | GPS session is already finalised by `endGame()` before "Next Match" is reachable; no coupling required |
