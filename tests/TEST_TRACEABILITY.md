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
- **FR-008** — Chosen half-length fixed once match starts — `tests/Test_RugbySettings_UI.mc::test_ui_select_profile_while_playing_is_blocked` — Partially Covered
- **FR-009** — Countdown updates immediately after user confirms duration (idle) — Planned: integration test — Not Covered
- **FR-010** — Persist last-selected game type (`lastGameType`/`matchProfileId`) — `tests/Test_RugbyMatchProfiles.mc::test_migrateLegacyProfile_defaults`, `tests/Test_RugbyMatchProfiles.mc::test_model_initialize_restores_stored_profile_id` — Covered

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
- `tests/Test_RugbyTimerPersistence.mc::test_recordYellowCard_pauses_live_match_and_tracks_totals` — verifies card entry pauses live play and records totals
- `tests/Test_RugbyTimerPersistence.mc::test_saveState_restores_playing_match_as_paused_snapshot` — verifies persisted live matches reopen as paused snapshots
- `tests/Test_RugbyTimerPersistence.mc::test_finalizeGameData_writes_summary_and_event_log` — verifies final summary/export persistence
- `tests/Test_RugbyGameModelServices.mc::test_start_pause_resume_game_wrappers` — verifies facade clock wrappers still drive the correct state transitions after service extraction
- `tests/Test_RugbyGameModelServices.mc::test_recordTry_starts_conversion_and_undo_reverts` — verifies scoring facade wrappers preserve try/conversion/undo behavior
- `tests/Test_RugbyGameModelServices.mc::test_saveGame_wrapper_writes_summary` — verifies the save facade still persists the final summary
- `tests/Test_RugbyGameModelServices.mc::test_preset_switching_updates_selected_profile_and_timer` — verifies built-in preset switching updates the selected profile and timing values
- `tests/Test_RugbyGameModelServices.mc::test_settings_mutation_order_stays_custom_and_persists_values` — verifies custom-setting mutation order preserves expected custom profile values
- `tests/Test_RugbyTypedEntries.mc::test_cardEntry_roundtrip_and_invalid_input` — verifies card wrapper roundtrip and invalid-input guard path
- `tests/Test_RugbyEventLogEntry.mc::test_eventLogEntry_roundtrip_and_display` — verifies event-log wrapper roundtrip and display formatting
- `tests/Test_RugbySettings_UI.mc::test_settings_support_profile_resolution_and_clamp` — verifies extracted pure settings helper behavior
- `tests/Test_RugbyTimerDelegateSupport.mc::test_delegateSupport_idleMinuteAdjustment_clamps` — verifies extracted delegate idle-minute rule
- `tests/Test_RugbyTimerDelegateSupport.mc::test_delegateSupport_overlayKeyMapping` — verifies extracted overlay key routing
- `tests/Test_RugbyTimerDelegateSupport.mc::test_delegateSupport_presetHoldKeys` — verifies hold-to-preset key gating
- `tests/Test_RugbyPersistenceRenderTypes.mc::test_persistedCardTimerEntry_roundtrip` — verifies serialized sanction-timer wrapper roundtrip
- `tests/Test_RugbyPersistenceRenderTypes.mc::test_persistedGameSnapshot_roundtrip` — verifies persisted snapshot wrapper roundtrip
- `tests/Test_RugbyPersistenceRenderTypes.mc::test_renderTypes_and_timerUpdateResult` — verifies renderer/timing typed adapter construction
- `tests/Test_RugbyRuntimeStatus.mc::test_statusMessage_is_one_shot` — verifies runtime status messages are consumed once
- `tests/Test_RugbyRuntimeStatus.mc::test_invalidSavedSnapshot_is_cleared_and_reported` — verifies malformed saved matches are cleared and surfaced to the UI

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
- `tests/Test_RugbyMatchProfiles.mc::test_model_initialize_restores_stored_profile_id` — Verifies a stored `matchProfileId` is respected on the next model initialization.

- `tests/Test_RugbyTimerCards_advanced.mc::test_yellow_multiple_ordering_and_numbering` — Verifies multiple yellow cards append and label numbering increments per-team.
- `tests/Test_RugbyTimerCards_advanced.mc::test_red_numbering_and_timed_entries` — Verifies red card numbering and timed entry creation under 15s rules.
- `tests/Test_RugbyTimerCards_advanced.mc::test_yellow_timer_sync_with_suspension` — Verifies card remaining time decreases with model suspension clock.
- `tests/Test_RugbyTimerCards_advanced.mc::test_red_permanent_in_7s_sets_flag_and_increments_counter` — Verifies 7s red is permanent, sets flag, and increments counter.
- `tests/Test_RugbyTimerPersistence.mc::test_recordYellowCard_pauses_live_match_and_tracks_totals` — Verifies yellow-card recording pauses live play, increments totals, and creates the expected active timer.
- `tests/Test_RugbyTimerPersistence.mc::test_saveState_restores_playing_match_as_paused_snapshot` — Verifies live persisted matches restore safely as paused resumable snapshots with sanction data intact.
- `tests/Test_RugbyTimerPersistence.mc::test_finalizeGameData_writes_summary_and_event_log` — Verifies finalized match summaries include totals and event-log export text.
- `tests/Test_RugbyGameModelServices.mc::test_start_pause_resume_game_wrappers` — Verifies `RugbyGameModel` clock facade methods still preserve start/pause/resume behavior after moving logic into helper services.
- `tests/Test_RugbyGameModelServices.mc::test_recordTry_starts_conversion_and_undo_reverts` — Verifies the scoring facade still triggers the conversion phase and undo reverses the scoring side effects.
- `tests/Test_RugbyGameModelServices.mc::test_saveGame_wrapper_writes_summary` — Verifies the snapshot facade still writes `lastGameSummary` via the public model method.
- `tests/Test_RugbyGameModelServices.mc::test_preset_switching_updates_selected_profile_and_timer` — Verifies sequential preset changes apply the expected built-in timing values.
- `tests/Test_RugbyGameModelServices.mc::test_settings_mutation_order_stays_custom_and_persists_values` — Verifies custom-setting mutations remain on the custom profile and persist the final expected values.
- `tests/Test_RugbyTypedEntries.mc::test_cardEntry_roundtrip_and_invalid_input` — Verifies the typed card wrapper preserves fields and safely rejects non-dictionary input.
- `tests/Test_RugbyEventLogEntry.mc::test_eventLogEntry_roundtrip_and_display` — Verifies event-log entries roundtrip through the wrapper and format the saved menu/export label correctly.
- `tests/Test_RugbySettings_UI.mc::test_settings_support_profile_resolution_and_clamp` — Verifies the extracted settings helper resolves preset ids and clamps picker values without needing the WatchUi runtime.
- `tests/Test_RugbyTimerDelegateSupport.mc::test_delegateSupport_idleMinuteAdjustment_clamps` — Verifies the extracted delegate helper clamps idle half-minute adjustments to the supported 1..99 range.
- `tests/Test_RugbyTimerDelegateSupport.mc::test_delegateSupport_overlayKeyMapping` — Verifies overlay hardware keys map to the correct logical conversion/penalty actions.
- `tests/Test_RugbyTimerDelegateSupport.mc::test_delegateSupport_presetHoldKeys` — Verifies only MENU and UP arm the hold-to-preset shortcut.
- `tests/Test_RugbyPersistenceRenderTypes.mc::test_persistedCardTimerEntry_roundtrip` — Verifies serialized sanction-timer adapters preserve timing/label/id fields.
- `tests/Test_RugbyPersistenceRenderTypes.mc::test_persistedGameSnapshot_roundtrip` — Verifies the persisted game snapshot adapter preserves key scoreboard/state fields.
- `tests/Test_RugbyPersistenceRenderTypes.mc::test_renderTypes_and_timerUpdateResult` — Verifies the typed render-layout/font/card-info and timer-update adapters are constructed as expected.
- `tests/Test_RugbyRuntimeStatus.mc::test_statusMessage_is_one_shot` — Verifies the model-level runtime status channel returns one message once and then clears.
- `tests/Test_RugbyRuntimeStatus.mc::test_invalidSavedSnapshot_is_cleared_and_reported` — Verifies malformed persisted snapshots are discarded and replaced with a safe idle reset plus a user-visible reset notice.

Status key: Covered = automated unit test present; Partially Covered = test covers some aspects; Planned = test should be added.

Next steps:
- Add UI/behavior/integration tests for Settings and picker flows (FR-001, FR-002, FR-003, FR-005, FR-006, FR-008, FR-009).
- Expand `Test_RugbyMatchProfiles` to assert `matchProfileId` persistence paths and `lastGameType` semantics.
- Keep this file updated as tests are added or requirements change.

Maintainability note:
- Test modules now include file-level purpose preambles so future additions can be routed into the right test file instead of duplicating coverage.
