# Test Traceability Matrix

This document maps functional requirements (from specs) to unit tests in `tests/`.

Format: Requirement ID — Short description — Test(s) (file::function) — Status

- **FR-001** — Allow any whole-minute half-length 1..99 — Planned: validation tests for UI/picker — Not Covered
- **FR-002** — Duration input available during new-game setup — Planned: UI integration tests — Not Covered
- **FR-003** — Duration input available in Settings when idle; disabled during match — Planned: UI/state tests — Not Covered
- **FR-004** — Persist chosen half-length per game type — `tests/Test_RugbyMatchProfiles.mc::test_store_and_retrieve_custom_profile` — Covered
- **FR-005** — Pre-populate duration picker with saved value — Planned: UI test — Not Covered
- **FR-006** — Enforce minimum duration of 1 minute (clamp) — Planned: add unit test for picker/accept path — Not Covered
- **FR-007** — Defaults when no saved value (7 min for 7s, 40 min for 15s) — `tests/Test_RugbyMatchProfiles.mc::test_migrateLegacyProfile_defaults` — Covered
- **FR-008** — Chosen half-length fixed once match starts — Planned: model state tests (pause/resume) — Not Covered
- **FR-009** — Countdown updates immediately after user confirms duration (idle) — Planned: integration test — Not Covered
- **FR-010** — Persist last-selected game type (`lastGameType`/`matchProfileId`) — `tests/Test_RugbyMatchProfiles.mc::test_migrateLegacyProfile_defaults` (partially) — Partially Covered

Card timers (requirements discovered from history and conversation):

- **CARDS-001** — Multiple card timers per team may be active concurrently; newer cards appear under earlier cards. — `tests/Test_RugbyTimerCards_advanced.mc::test_yellow_multiple_ordering_and_numbering` — Covered
- **CARDS-002** — Card numbering increments per-team independently for yellow and red cards. — `tests/Test_RugbyTimerCards_advanced.mc::test_yellow_multiple_ordering_and_numbering`, `tests/Test_RugbyTimerCards_advanced.mc::test_red_numbering_and_timed_entries` — Covered
- **CARDS-003** — Timers for card entries are synchronized to the model's suspension clock so their remaining time decreases with the game timer. — `tests/Test_RugbyTimerCards_advanced.mc::test_yellow_timer_sync_with_suspension` — Covered
- **CARDS-004** — Under 7s rules, red cards are permanent (flag set) and still increment the red label counter. — `tests/Test_RugbyTimerCards_advanced.mc::test_red_permanent_in_7s_sets_flag_and_increments_counter` — Covered

Next steps: add UI/integration tests that assert the visual stacking order (rendered y positions) and end-to-end behavior via the simulator Test Explorer or a simulator-driven script.

Additional unit tests added (cards/timing):

- `tests/Test_RugbyTimerTiming.mc::test_formatTime_65` — verifies `RugbyTimerTiming.formatTime(65)` output
- `tests/Test_RugbyTimerTiming.mc::test_formatTime_negative` — verifies negative input handling
- `tests/Test_RugbyTimerTiming.mc::test_getDisplayCountdownSeconds_nonnull` — verifies countdown behavior for numeric input
- `tests/Test_RugbyTimerTiming.mc::test_getDisplayCountdownSeconds_null` — verifies null input fallback
- `tests/Test_RugbyTimerCards.mc::test_getEntryRemaining_live` — verifies live remaining calculation
- `tests/Test_RugbyTimerCards.mc::test_getEntryRemaining_stored` — verifies stored remaining path
- `tests/Test_RugbyTimerCards.mc::test_updateYellowTimers_basic` — verifies update/remaining calculation and structure

Detailed test purposes (file::function -> purpose):

- `tests/Test_RugbyTimerTiming.mc::test_formatTime_65` — Verifies MM:SS formatting for a typical value (65 -> "01:05").
- `tests/Test_RugbyTimerTiming.mc::test_formatTime_negative` — Verifies negative inputs produce "00:00".
- `tests/Test_RugbyTimerTiming.mc::test_getDisplayCountdownSeconds_nonnull` — Verifies display normalization for numeric inputs (>= input).
- `tests/Test_RugbyTimerTiming.mc::test_getDisplayCountdownSeconds_null` — Verifies null/negative input returns 0.

- `tests/Test_RugbyTimerCards.mc::test_getEntryRemaining_live` — Verifies live remaining calculation when `startTime` and `clockValue` are present.
- `tests/Test_RugbyTimerCards.mc::test_getEntryRemaining_stored` — Verifies stored `remaining` is used when live values are absent.
- `tests/Test_RugbyTimerCards.mc::test_updateYellowTimers_basic` — Verifies update path produces one timer with positive remaining.

- `tests/Test_RugbyMatchProfiles.mc::test_store_and_retrieve_custom_profile` — Verifies storing a custom profile persists expected fields.
- `tests/Test_RugbyMatchProfiles.mc::test_migrateLegacyProfile_defaults` — Verifies legacy migration returns a safe default profile id when legacy keys are absent.

- `tests/Test_RugbyTimerCards_advanced.mc::test_yellow_multiple_ordering_and_numbering` — Verifies multiple yellow cards append and label numbering increments per-team.
- `tests/Test_RugbyTimerCards_advanced.mc::test_red_numbering_and_timed_entries` — Verifies red card numbering and timed entry creation under 15s rules.
- `tests/Test_RugbyTimerCards_advanced.mc::test_yellow_timer_sync_with_suspension` — Verifies card remaining time decreases with model suspension clock.
- `tests/Test_RugbyTimerCards_advanced.mc::test_red_permanent_in_7s_sets_flag_and_increments_counter` — Verifies 7s red is permanent, sets flag, and increments counter.

Status key: Covered = automated unit test present; Partially Covered = test covers some aspects; Planned = test should be added.

Next steps:
- Add UI/behavior/integration tests for Settings and picker flows (FR-001, FR-002, FR-003, FR-005, FR-006, FR-008, FR-009).
- Expand `Test_RugbyMatchProfiles` to assert `matchProfileId` persistence paths and `lastGameType` semantics.
- Keep this file updated as tests are added or requirements change.
