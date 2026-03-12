# Implementation Plan: 001-custom-half-timer

**Feature Branch**: `001-custom-half-timer`  
**Created**: 2026-03-10  
**Spec**: `specs/001-custom-half-timer/spec.md`  
**Research**: `specs/001-custom-half-timer/research.md`  
**Data Model**: `specs/001-custom-half-timer/data-model.md`

---

## Technical Context

| Item | Value |
|---|---|
| Language | Monkey C (Garmin Connect IQ) |
| SDK | `connectiq-sdk-win-8.3.0-2025-09-22-5813687a0` |
| Build target for CI | `fenix6_sim` |
| Storage API | `Toybox.Application.Storage` (flat key-value) |
| UI API | `WatchUi.Picker`, `WatchUi.PickerFactory`, `WatchUi.PickerDelegate`, `WatchUi.Menu2`, `WatchUi.MenuItem` |
| Affected modules | `RugbyGameModel.mc`, `RugbySettings.mc`, `RugbyTimerDelegate.mc` |
| Unaffected modules | `RugbyTimerRenderer.mc`, `RugbyTimerTiming.mc`, `RugbyTimerCards.mc`, `RugbyTimerOverlay.mc`, `RugbyTimerPersistence.mc`, `RugbyTimerEventLog.mc`, `RugbyTimerView.mc` |

---

## Constitution Check

| Principle | Assessment |
|---|---|
| **I. Module Separation** | ✅ Changes are contained within their correct modules: persistence logic in Model, UI logic in Delegate/Settings. No cross-module field mutations. |
| **II. Build-First Release Gate** | ✅ Gate applies after implementation. `monkeybrains.jar` must be run targeting `fenix6_sim` before commit. |
| **III. Manual Verification** | ✅ Gate applies before release. Three test flows required (see quickstart.md). |
| **IV. Documentation Discipline** | ✅ `project_technical_document.md` must be updated post-implementation to reflect new storage keys. `log.md` must record build command and result. |
| **V. Coding Convention Compliance** | ✅ All new code must use 4-space indent, camelCase methods, no type annotations on locals, inline comments on any non-trivial expressions. |

**Gate decision**: No violations. Proceed.

---

## Scope

This plan covers **only** the changes required to make the half-timer fully customizable with per-game-type persistence. No layout changes, no new source files, no changes to card timers, scoring, GPS, or event log.

---

## Phase 0: Research (complete)

See `research.md` for full findings. Summary of resolved decisions:

- Storage: two new per-type keys (`halfDuration7s`, `halfDuration15s`), legacy `countdownTimer` kept as a read-only fallback.
- `rugby7s` boolean fulfils the `lastGameType` requirement — no new key needed.
- Settings "Half Timer" item disabled via `{:enabled => false}` when match is in progress.
- `setGameType()` must load from per-type key, not overwrite with type default.
- `GameTypePromptDelegate.onSelect()` must pre-fill picker from per-type Storage.

---

## Phase 1: Design (complete)

See `data-model.md` for full entity, storage, and method-contract definitions.

---

## Phase 2: Implementation Tasks

Tasks are ordered by dependency. Each task is a single, independently buildable change.

---

### Task 1 — `RugbyGameModel.mc`: Fix `initialize()` to read per-type duration

**File**: `source/RugbyGameModel.mc`  
**Method**: `initialize()`  
**Change**: Replace the block that reads `countdownTimer` from Storage with the per-type chain.

**Before (lines ~152–159)**:
```monkeyc
halfDuration = is7s ? 420 : 2400; // 7 min or 40 min in seconds

// Load countdown timer setting
var savedCountdown = Storage.getValue("countdownTimer");
if (savedCountdown == null) {
    countdownTimer = halfDuration;  // Default to half duration
} else {
    countdownTimer = savedCountdown;
}
```

**After**:
```monkeyc
var typeKey = is7s ? "halfDuration7s" : "halfDuration15s";
var savedDuration = Storage.getValue(typeKey);
if (savedDuration == null) {
    // Legacy fallback for devices with an existing countdownTimer save
    savedDuration = Storage.getValue("countdownTimer");
}
halfDuration = (savedDuration != null) ? savedDuration : (is7s ? 420 : 2400);
countdownTimer = halfDuration;
```

---

### Task 2 — `RugbyGameModel.mc`: Fix `setGameType()` to load per-type duration

**File**: `source/RugbyGameModel.mc`  
**Method**: `setGameType(is7sFlag)`  
**Change**: Instead of writing `countdownTimer = halfDuration` with a hardcoded type default, load from the per-type key.

**Before**:
```monkeyc
function setGameType(is7sFlag) {
    is7s = is7sFlag;
    Storage.setValue("rugby7s", is7sFlag);
    halfDuration = is7s ? 420 : 2400;
    countdownTimer = halfDuration;
    if (gameState == STATE_IDLE) {
        countdownRemaining = countdownTimer;
    }
}
```

**After**:
```monkeyc
function setGameType(is7sFlag) {
    is7s = is7sFlag;
    Storage.setValue("rugby7s", is7sFlag);
    // Load the saved duration for the newly selected game type
    var typeKey = is7sFlag ? "halfDuration7s" : "halfDuration15s";
    var savedDuration = Storage.getValue(typeKey);
    if (savedDuration == null) {
        savedDuration = Storage.getValue("countdownTimer"); // legacy fallback
    }
    halfDuration = (savedDuration != null) ? savedDuration : (is7sFlag ? 420 : 2400);
    countdownTimer = halfDuration;
    if (gameState == STATE_IDLE) {
        countdownRemaining = countdownTimer;
    }
}
```

---

### Task 3 — `RugbyGameModel.mc`: Fix `setHalfDuration()` to write per-type key

**File**: `source/RugbyGameModel.mc`  
**Method**: `setHalfDuration(seconds)`  
**Change**: Write to `halfDuration7s` or `halfDuration15s` instead of generic `countdownTimer`.

**Before**:
```monkeyc
function setHalfDuration(seconds) {
    halfDuration = seconds;
    countdownTimer = seconds;
    Storage.setValue("countdownTimer", seconds);
    if (gameState == STATE_IDLE) {
        countdownRemaining = seconds;
    }
}
```

**After**:
```monkeyc
function setHalfDuration(seconds) {
    halfDuration = seconds;
    countdownTimer = seconds;
    // Write to the per-type key so the correct duration is restored on game-type recall
    var typeKey = is7s ? "halfDuration7s" : "halfDuration15s";
    Storage.setValue(typeKey, seconds);
    if (gameState == STATE_IDLE) {
        countdownRemaining = seconds;
    }
}
```

---

### Task 4 — `RugbyTimerDelegate.mc`: Pre-fill new-game picker from per-type storage

**File**: `source/RugbyTimerDelegate.mc`  
**Method**: `GameTypePromptDelegate.onSelect(item)`  
**Change**: Read the saved per-type duration (with fallback) instead of using a hardcoded default.

**Before**:
```monkeyc
function onSelect(item) {
    var is7s = (item.getId() == :gt_7s);
    // Default starting value reflects the standard game length; user scrolls freely to any minute
    var defaultMinutes = is7s ? 7 : 40;
    WatchUi.pushView(new MinutesPicker(defaultMinutes), new NewGameTimerPickerDelegate(is7s, model), WatchUi.SLIDE_UP);
}
```

**After**:
```monkeyc
function onSelect(item) {
    var is7s = (item.getId() == :gt_7s);
    // Pre-fill picker with the saved duration for this game type (FR-005)
    var typeKey = is7s ? "halfDuration7s" : "halfDuration15s";
    var savedSecs = Storage.getValue(typeKey);
    if (savedSecs == null) {
        savedSecs = Storage.getValue("countdownTimer"); // legacy fallback
    }
    var defaultMinutes = (savedSecs != null) ? (savedSecs / 60) : (is7s ? 7 : 40);
    if (defaultMinutes < 1) { defaultMinutes = 1; }
    WatchUi.pushView(new MinutesPicker(defaultMinutes), new NewGameTimerPickerDelegate(is7s, model), WatchUi.SLIDE_UP);
}
```

---

### Task 5 — `RugbySettings.mc`: Disable "Half Timer" item during match + read per-type key

**File**: `source/RugbySettings.mc`  
**Class**: `RugbySettingsMenu.initialize()`  
**Change (a)**: Read per-type key (with fallback) for the sub-label instead of generic `countdownTimer`.  
**Change (b)**: Pass `{:enabled => false}` to the "Half Timer" `MenuItem` constructor when a match is in progress.

**Before**:
```monkeyc
// Add countdown timer setting
var countdownTimer = Storage.getValue("countdownTimer");
if (countdownTimer == null) {
    countdownTimer = is7s ? 420 : 2400;  // Default based on game type
}
var timerStr = formatTime(countdownTimer);
addItem(new WatchUi.MenuItem("Half Timer", timerStr, :countdown_timer, null));
```

**After**:
```monkeyc
// Read per-type saved duration for the sub-label (FR-005)
var typeKey = is7s ? "halfDuration7s" : "halfDuration15s";
var savedDuration = Storage.getValue(typeKey);
if (savedDuration == null) { savedDuration = Storage.getValue("countdownTimer"); }
if (savedDuration == null) { savedDuration = is7s ? 420 : 2400; }
var timerStr = formatTime(savedDuration);
// Disable while a match is in progress so duration is immutable once started (FR-008 / FR-003)
var app = Application.getApp() as RugbyTimerApp;
var inGame = (app != null && app.model != null && app.model.gameState != 0);
addItem(new WatchUi.MenuItem("Half Timer", timerStr, :countdown_timer, {:enabled => !inGame}));
```

---

### Task 6 — `RugbySettings.mc`: Fix `TimerPickerDelegate.onAccept()` to write per-type key

**File**: `source/RugbySettings.mc`  
**Class**: `TimerPickerDelegate`  
**Method**: `onAccept(values)`  
**Change**: Write to the per-type key instead of generic `countdownTimer`.

**Before**:
```monkeyc
function onAccept(values) {
    var minutes = values[0] * 10 + values[1];
    if (minutes < 1) { minutes = 1; }
    var seconds = minutes * 60;
    Storage.setValue("countdownTimer", seconds);
    if (mParentItem != null) {
        mParentItem.setSubLabel(minutes.format("%02d") + ":00");
    }
    var app = Application.getApp() as RugbyTimerApp;
    if (app != null && app.model != null && app.model.gameState == 0) {
        app.model.countdownTimer = seconds;
        app.model.countdownRemaining = seconds;
        WatchUi.requestUpdate();
    }
    WatchUi.popView(WatchUi.SLIDE_DOWN);
    return true;
}
```

**After**:
```monkeyc
function onAccept(values) {
    var minutes = values[0] * 10 + values[1];
    if (minutes < 1) { minutes = 1; }
    var seconds = minutes * 60;
    // Write to per-type key so each game type remembers its own duration
    var is7s = Storage.getValue("rugby7s");
    if (is7s == null) { is7s = false; }
    var typeKey = is7s ? "halfDuration7s" : "halfDuration15s";
    Storage.setValue(typeKey, seconds);
    if (mParentItem != null) {
        mParentItem.setSubLabel(minutes.format("%02d") + ":00");
    }
    var app = Application.getApp() as RugbyTimerApp;
    if (app != null && app.model != null && app.model.gameState == 0) {
        app.model.countdownTimer = seconds;
        app.model.countdownRemaining = seconds;
        WatchUi.requestUpdate();
    }
    WatchUi.popView(WatchUi.SLIDE_DOWN);
    return true;
}
```

---

## Phase 3: Verification Checklist

These manual test flows MUST pass on `fenix6_sim` before any release (Constitution Principle III).

See `quickstart.md` for step-by-step instructions.

| Flow | Acceptance scenario(s) covered |
|---|---|
| New-game picker pre-fills from per-type storage | US1 AS 2 & 3, FR-005 |
| Custom duration persists across app restart | US3 AS 1 & 2, FR-004 |
| Settings "Half Timer" disabled during match | US2 AS 3, FR-003, FR-008 |
| Alternating game types recall independent durations | US3 AS 3, FR-004 |
| 00 picker value clamped to 01 | FR-006 |
| Settings "Half Timer" edits current game type only | US2 AS 1, FR-003 |

---

## Phase 4: Documentation

After all tasks pass verification, update:

- `log.md` — Record build command, `fenix6_sim` target, PASS/FAIL, date (Constitution Principle II & IV).
- `project_technical_document.md` — Add/update the Storage key table to include `halfDuration7s`, `halfDuration15s`, and document that `countdownTimer` is a legacy read-only fallback (Constitution Principle IV).

---

## No New Source Files

All changes are contained in three existing modules. No new `.mc` files are needed. This satisfies Constitution Principle I (changes fit within existing module responsibilities).

---

## No External Contracts

This is an internal watch app with no public APIs, HTTP endpoints, or inter-process interfaces. The contracts/ directory is not applicable.
