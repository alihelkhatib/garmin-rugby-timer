# Quickstart: Manual Verification — 001-custom-half-timer

**Branch**: `001-custom-half-timer`  
**Simulator target**: `fenix6_sim`

Run all flows below on the Connect IQ simulator after building with `monkeybrains.jar`. Record results in `log.md`.

---

## Pre-flight

1. Build the `.prg`: run `monkeybrains.jar` targeting `fenix6_sim`. Confirm zero errors.
2. Launch the `fenix6_sim` simulator and load the fresh `.prg`.
3. **Clear storage** before starting: use the simulator's "Clear App Storage" option so you start with a blank slate.

---

## Flow 1 — New-game picker pre-fills from saved value (US1, FR-005)

**Goal**: Confirm the picker opens at the last-saved duration for the selected game type, not the hardcoded default.

| Step | Action | Expected result |
|---|---|---|
| 1 | On idle screen, trigger the "New Game" prompt (tap SELECT or however the game-type menu is invoked) | Game Type menu appears with "Rugby 7s" and "Rugby 15s" |
| 2 | Select "Rugby 7s" | MinutesPicker opens; tens column = 0, units column = 7 (default 7 min, no prior save) |
| 3 | Scroll units to 2 (= 02 min), confirm | Idle screen countdown shows 02:00 |
| 4 | Reset game (Back → Reset Game) | Countdown resets to 02:00 (saved value) |
| 5 | Trigger New Game again, select "Rugby 7s" | Picker opens with tens = 0, units = 2 (not 7) ✅ |
| 6 | Cancel without confirming | Countdown still shows 02:00 ✅ |

**Pass criterion**: Step 5 shows 02 pre-filled; Step 6 leaves duration unchanged.

---

## Flow 2 — Custom duration persists across app restart (US3, FR-004)

**Goal**: Confirm per-type durations survive app close/reopen.

| Step | Action | Expected result |
|---|---|---|
| 1 | Set Rugby 7s half-length to 08 minutes (via new-game picker), confirm | Idle countdown shows 08:00 |
| 2 | Trigger New Game, select "Rugby 15s", set to 35 minutes, confirm | Idle countdown shows 35:00 |
| 3 | Close the app in the simulator (Stop App) | App exits |
| 4 | Relaunch the app | Idle countdown shows 35:00 (last-used was 15s with 35 min) |
| 5 | Trigger New Game, select "Rugby 15s" | Picker pre-fills at 35 ✅ |
| 6 | Cancel, trigger New Game, select "Rugby 7s" | Picker pre-fills at 08 ✅ |

**Pass criterion**: Steps 5 and 6 each show the correct per-type saved value.

---

## Flow 3 — Settings "Half Timer" disabled during match (US2 AS 3, FR-003, FR-008)

**Goal**: Confirm the duration cannot be changed once a match starts.

| Step | Action | Expected result |
|---|---|---|
| 1 | Start a game (set game type + duration, press SELECT to start) | Game clock running |
| 2 | Open Settings (Menu button → Settings or however accessed) | Settings menu appears |
| 3 | Navigate to "Half Timer" item | Item is greyed out / non-interactive; cannot be selected |
| 4 | Attempt to press SELECT on the Half Timer item | Nothing happens (item remains disabled) |
| 5 | End the game (Back → End Game or Reset) | Game returns to STATE_IDLE |
| 6 | Re-open Settings | "Half Timer" item is now enabled and tappable |

**Pass criterion**: Steps 3–4 show the item is disabled; Step 6 shows it re-enables.

---

## Flow 4 — Settings "Half Timer" edits current game type (US2 AS 1, FR-003)

**Goal**: Confirm that editing the half timer in Settings updates the current game type's storage key.

| Step | Action | Expected result |
|---|---|---|
| 1 | Ensure a 7s game is active (idle, Rugby 7s selected) | Idle screen visible |
| 2 | Open Settings → Half Timer | Picker opens at current 7s saved value |
| 3 | Scroll to 18, confirm | Settings sub-label updates to "18:00"; idle countdown updates to 18:00 |
| 4 | Trigger New Game, select "Rugby 7s" | Picker pre-fills at 18 ✅ |
| 5 | Cancel; trigger New Game, select "Rugby 15s" | Picker pre-fills at 35 (or whatever was set in Flow 2) — NOT 18 ✅ |

**Pass criterion**: Step 4 shows 18; Step 5 shows the 15s value unchanged.

---

## Flow 5 — Zero-minutes clamp (FR-006)

**Goal**: Confirm picking 00 minutes produces 01 and no crash.

| Step | Action | Expected result |
|---|---|---|
| 1 | Open new-game picker (any game type) | MinutesPicker visible |
| 2 | Scroll both columns to 0 (tens = 0, units = 0) | Shows "00" |
| 3 | Confirm | Idle countdown shows 01:00 (clamped to 1 min) ✅; no crash |

**Pass criterion**: Step 3 shows 01:00.

---

## Log Entry Template

After completing all flows, add to `log.md`:

```
## [DATE] — 001-custom-half-timer verification

Build command: java -jar <SDK_PATH>/bin/monkeybrains.jar -o bin/rugbytimer.prg -f monkey.jungle -y developer_key -d fenix6_sim -w
Build result: PASS / FAIL

Manual flows:
  Flow 1 — New-game picker pre-fill:    PASS / FAIL
  Flow 2 — Duration persists on restart: PASS / FAIL
  Flow 3 — Settings disabled in-match:  PASS / FAIL
  Flow 4 — Settings edits current type: PASS / FAIL
  Flow 5 — Zero-clamp to 1 min:         PASS / FAIL

Notes: <any observations>
```
