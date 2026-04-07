# Test Traceability Matrix

This document maps functional requirements (from specs) to unit tests in `tests/`.

Format: Requirement ID — Short description — Test(s) (file::function) — Status

- **FR-001** — Allow any whole-minute half-length 1..99 — `tests/Test_RugbyTimerDelegateSupport.mc::test_delegateSupport_idleMinuteAdjustment_clamps`, `tests/Test_RugbySettings_UI.mc::test_ui_minutes_picker_sets_half_duration` — Partially Covered
- **FR-002** — Duration input available during new-game setup — `tests/Test_RugbyGameModelServices.mc::test_idle_half_duration_change_resets_idle_runtime_fields`, `tests/Test_RugbyGameModelServices.mc::test_model_initialize_recovers_from_invalid_custom_idle_profile`, `tests/Test_RugbyGameModelServices.mc::test_startGame_uses_configured_halfDuration_even_if_countdownTimer_stale`, `tests/Test_RugbyTimerViewSupport.mc::test_renderer_mainCountdown_uses_half_duration_while_idle`, `tests/Test_RugbyTimerViewSupport.mc::test_viewSupport_idleConfiguredSeconds_prefers_profile_config_and_safe_fallback`, `tests/Test_RugbyMatchStateSupport.mc::test_matchIntegrity_reconcile_idle_restores_config_owned_fields` — Covered
- **FR-003** — Duration input available in Settings when idle; disabled during match — Planned: UI/state tests — Not Covered
- **FR-004** — Persist chosen half-length per game type — `tests/Test_RugbyMatchProfiles.mc::test_store_and_retrieve_custom_profile` — Covered
- **FR-005** — Pre-populate duration picker with saved value — Planned: UI test — Not Covered
- **FR-006** — Enforce minimum duration of 1 minute (clamp) — `tests/Test_RugbyTimerDelegateSupport.mc::test_delegateSupport_idleMinuteAdjustment_clamps`, `tests/Test_RugbySettings_UI.mc::test_settings_support_minutes_and_timer_mapping` — Covered
- **FR-007** — Defaults when no saved value (7 min for 7s, 40 min for 15s) — `tests/Test_RugbyMatchProfiles.mc::test_migrateLegacyProfile_defaults` — Covered
- **FR-008** — Chosen half-length fixed once match starts — `tests/Test_RugbySettings_UI.mc::test_ui_select_profile_while_playing_is_blocked` — Partially Covered
- **FR-009** — Countdown updates immediately after user confirms duration (idle) — `tests/Test_RugbyGameModelServices.mc::test_idle_half_duration_change_resets_idle_runtime_fields`, `tests/Test_RugbyTimerViewSupport.mc::test_renderer_mainCountdown_uses_half_duration_while_idle` — Covered
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
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_preset_change_persists_and_restores` — verifies preset switching survives full model reinitialization
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_start_pause_resume_restore_flow` — verifies start/pause/resume plus persisted paused restore
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_card_timers_survive_persist_restore` — verifies yellow/red sanction timers survive persistence with remaining time intact
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_startGame_uses_strict_rugby_recording` — verifies start flow either opens rugby recording or reports a strict rugby-only failure
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_conversion_made_returns_to_play_and_scores` — verifies a made conversion awards points and resumes open play
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_conversion_miss_returns_to_play_without_extra_score` — verifies a missed conversion resumes open play without extra points
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_penalty_timer_starts_and_expiry_resumes_play` — verifies the penalty-timer path enters special state and returns to play on expiry
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_second_half_then_end_game` — verifies halftime restart and the second-half end-game transition
- `tests/Test_RugbyTimerViewSupport.mc::test_viewSupport_overlayVisibility_rules` — verifies extracted view overlay visibility rules
- `tests/Test_RugbyTimerViewSupport.mc::test_viewSupport_hintMode_rules` — verifies extracted hint-mode routing
- `tests/Test_RugbyTimerViewSupport.mc::test_viewSupport_toast_visibility_rules` — verifies extracted toast visibility rules
- `tests/Test_RugbyTimerViewSupport.mc::test_renderer_mainCountdown_uses_half_duration_while_idle` — verifies idle countdown derives only from configured half duration
- `tests/Test_RugbyTimerViewSupport.mc::test_viewSupport_mainCountdown_uses_halftime_break_then_half_duration` — verifies halftime render countdown switches from break timer to half-duration ready state
- `tests/Test_RugbyTimerViewSupport.mc::test_viewSupport_special_and_suspension_clocks_share_snapshot_math` — verifies special and suspension clocks use the shared render snapshot rules
- `tests/Test_RugbyTimerApp.mc::test_app_reuses_initialized_model_across_settings_and_main_view` — verifies settings-driven profile changes are not lost when the main view is created
- `tests/Test_RugbyTeamIdentitySupport.mc::test_teamIdentitySupport_normalizes_invalid_mode` — verifies unknown team-label modes fall back safely
- `tests/Test_RugbyTeamIdentitySupport.mc::test_teamIdentitySupport_resolves_labels_for_preset` — verifies preset pair resolution for score/event-log labels
- `tests/Test_RugbyTeamIdentitySupport.mc::test_teamIdentitySupport_builds_event_description_from_model` — verifies event-log wording uses the active resolved team label
- `tests/Test_RugbyTeamIdentitySupport.mc::test_teamIdentitySupport_compact_scoreBand_labels` — verifies compact score-band aliases for tight round-watch layouts
- `tests/Test_RugbyMatchProfiles_Settings.mc::test_setTeamLabelMode_promotes_to_custom_and_persists` — verifies team-label edits promote the active preset to `Custom` and persist across reloads
- `tests/Test_RugbyPersistenceRenderTypes.mc::test_renderer_topBand_safeBounds_and_fit` — verifies round-watch safe bounds and label-fit decisions for the top score band
- `tests/Test_RugbyRuntimeStatus.mc::test_runtimeNotice_wraps_legacy_strings_and_preserves_message` — verifies legacy string notices normalize through the typed runtime-notice wrapper
- `tests/Test_RugbyTimerPersistence.mc::test_buildSnapshot_normalizes_history_payloads` — verifies snapshot building normalizes score-history and event-log entries through typed wrappers before saving
- `tests/Test_RugbyTimerPersistence.mc::test_finalizeGameData_normalizes_summary_card_entries` — verifies summary saves drop malformed card entries instead of persisting them

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
- `tests/Test_RugbyMatchProfiles.mc::test_stored_custom_profile_invalid_zero_halfDuration_falls_back_safely` — Verifies poisoned custom-profile timing values are normalized to a safe built-in baseline before startup/render paths consume them.

- `tests/Test_RugbyTimerCards_advanced.mc::test_yellow_multiple_ordering_and_numbering` — Verifies multiple yellow cards append and label numbering increments per-team.
- `tests/Test_RugbyTimerCards_advanced.mc::test_red_numbering_and_timed_entries` — Verifies red card numbering and timed entry creation under 15s rules.
- `tests/Test_RugbyTimerCards_advanced.mc::test_yellow_timer_sync_with_suspension` — Verifies card remaining time decreases with model suspension clock.
- `tests/Test_RugbyTimerCards_advanced.mc::test_red_permanent_in_7s_sets_flag_and_increments_counter` — Verifies 7s red is permanent, sets flag, and increments counter.
- `tests/Test_RugbyTimerPersistence.mc::test_recordYellowCard_pauses_live_match_and_tracks_totals` — Verifies yellow-card recording pauses live play, increments totals, and creates the expected active timer.
- `tests/Test_RugbyTimerPersistence.mc::test_saveState_restores_playing_match_as_paused_snapshot` — Verifies live persisted matches restore safely as paused resumable snapshots with sanction data intact.
- `tests/Test_RugbyTimerPersistence.mc::test_finalizeGameData_writes_summary_and_event_log` — Verifies finalized match summaries include totals and event-log export text.
- `tests/Test_RugbyTimerPersistence.mc::test_persistState_idle_match_clears_saved_snapshot` — Verifies idle/pre-kickoff state cannot persist into the resumable live-match snapshot slot.
- `tests/Test_RugbyGameModelServices.mc::test_start_pause_resume_game_wrappers` — Verifies `RugbyGameModel` clock facade methods still preserve start/pause/resume behavior after moving logic into helper services.
- `tests/Test_RugbyGameModelServices.mc::test_recordTry_starts_conversion_and_undo_reverts` — Verifies the scoring facade still triggers the conversion phase and undo reverses the scoring side effects.
- `tests/Test_RugbyGameModelServices.mc::test_saveGame_wrapper_writes_summary` — Verifies the snapshot facade still writes `lastGameSummary` via the public model method.
- `tests/Test_RugbyGameModelServices.mc::test_preset_switching_updates_selected_profile_and_timer` — Verifies sequential preset changes apply the expected built-in timing values.
- `tests/Test_RugbyGameModelServices.mc::test_settings_mutation_order_stays_custom_and_persists_values` — Verifies custom-setting mutations remain on the custom profile and persist the final expected values.
- `tests/Test_RugbyGameModelServices.mc::test_idle_half_duration_change_resets_idle_runtime_fields` — Verifies idle half-length changes reset only the idle runtime countdown fields and leave the screen driven by configuration.
- `tests/Test_RugbyGameModelServices.mc::test_model_initialize_recovers_from_invalid_custom_idle_profile` — Verifies startup recovers to a sane idle countdown when stored custom-profile timing values have been corrupted.
- `tests/Test_RugbyGameModelServices.mc::test_startGame_uses_configured_halfDuration_even_if_countdownTimer_stale` — Verifies kickoff reseeds the half countdown from configuration instead of trusting a stale runtime countdown field.
- `tests/Test_RugbyTypedEntries.mc::test_cardEntry_roundtrip_and_invalid_input` — Verifies the typed card wrapper preserves fields and safely rejects non-dictionary input.
- `tests/Test_RugbyEventLogEntry.mc::test_eventLogEntry_roundtrip_and_display` — Verifies event-log entries roundtrip through the wrapper and format the saved menu/export label correctly.
- `tests/Test_RugbySettings_UI.mc::test_settings_support_profile_resolution_and_clamp` — Verifies the extracted settings helper resolves preset ids and clamps picker values without needing the WatchUi runtime.
- `tests/Test_RugbySettings_UI.mc::test_settings_support_item_resolution_falls_back_to_labels` — Verifies settings choices still resolve correctly when a device returns labels or null ids instead of the expected item identifier.
- `tests/Test_RugbyTimerDelegateSupport.mc::test_delegateSupport_idleMinuteAdjustment_clamps` — Verifies the extracted delegate helper clamps idle half-minute adjustments to the supported 1..99 range.
- `tests/Test_RugbyTimerDelegateSupport.mc::test_delegateSupport_overlayKeyMapping` — Verifies overlay hardware keys map to the correct logical conversion/penalty actions.
- `tests/Test_RugbyTimerDelegateSupport.mc::test_delegateSupport_presetHoldKeys` — Verifies only MENU and UP arm the hold-to-preset shortcut.
- `tests/Test_RugbyPersistenceRenderTypes.mc::test_persistedCardTimerEntry_roundtrip` — Verifies serialized sanction-timer adapters preserve timing/label/id fields.
- `tests/Test_RugbyPersistenceRenderTypes.mc::test_persistedGameSnapshot_roundtrip` — Verifies the persisted game snapshot adapter preserves key scoreboard/state fields.
- `tests/Test_RugbyPersistenceRenderTypes.mc::test_renderTypes_and_timerUpdateResult` — Verifies the typed render-layout/font/card-info and timer-update adapters are constructed as expected.
- `tests/Test_RugbyRuntimeStatus.mc::test_statusMessage_is_one_shot` — Verifies the model-level runtime status channel returns one message once and then clears.
- `tests/Test_RugbyRuntimeStatus.mc::test_invalidSavedSnapshot_is_cleared_and_reported` — Verifies malformed persisted snapshots are discarded and replaced with a safe idle reset plus a user-visible reset notice.
- `tests/Test_RugbyRuntimeStatus.mc::test_zero_countdown_savedSnapshot_is_cleared_and_reported` — Verifies zero-duration saved snapshots are treated as invalid and cleared before startup can strand the app in a broken pseudo-idle state.
- `tests/Test_RugbyMatchStateSupport.mc::test_matchIntegrity_reconcile_invalid_state_falls_back_to_idle` — Verifies unknown runtime states normalize back to a sane idle baseline instead of disabling idle prompts/input.
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_preset_change_persists_and_restores` — Verifies preset changes persist through a fresh model initialization cycle.
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_start_pause_resume_restore_flow` — Verifies the live clock flow can start, pause, persist, restore paused, and resume safely.
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_card_timers_survive_persist_restore` — Verifies sanction timing remains intact after persistence/restore for both yellow and timed red cards.
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_startGame_uses_strict_rugby_recording` — Verifies match start keeps the rugby-only recording contract by either opening a session or surfacing a rugby-specific failure state.
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_conversion_made_returns_to_play_and_scores` — Verifies the conversion success path restores playing state and adds the expected score.
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_conversion_miss_returns_to_play_without_extra_score` — Verifies the conversion miss path restores playing state without adding points.
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_penalty_timer_starts_and_expiry_resumes_play` — Verifies penalty special-timer state starts correctly and expiry returns to open play.
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_resumePlay_clears_special_timer_runtime` — Verifies resuming normal play clears special-timer runtime fields so stale conversion/penalty state does not leak across transitions.
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_startSecondHalf_clears_break_timer_runtime` — Verifies halftime-to-second-half transition clears break-only timer state and restores the normal half countdown.
- `tests/Test_RugbyIntegrationFlows.mc::test_integration_second_half_then_end_game` — Verifies halftime restart and manual end-game completion in the second half.
- `tests/Test_RugbyTimerViewSupport.mc::test_viewSupport_overlayVisibility_rules` — Verifies conversion/penalty overlay visibility decisions moved out of `RugbyTimerView`.
- `tests/Test_RugbyTimerViewSupport.mc::test_viewSupport_hintMode_rules` — Verifies the extracted main-screen hint selection logic.
- `tests/Test_RugbyTimerViewSupport.mc::test_viewSupport_toast_visibility_rules` — Verifies when non-overlay status toasts are allowed to render.
- `tests/Test_RugbyTimerViewSupport.mc::test_viewSupport_idleConfiguredSeconds_prefers_profile_config_and_safe_fallback` — Verifies idle setup resolves from configured profile timing before stale runtime countdown values and still falls back to a safe default when every stored timer field is invalid.
- `tests/Test_RugbyTimerViewSupport.mc::test_viewSupport_mainCountdown_keeps_half_duration_during_halftime_break` — Verifies the halftime break countdown now lives on the special countdown path and does not overwrite the main half countdown contract.
- `tests/Test_RugbyTimerApp.mc::test_app_reuses_initialized_model_across_settings_and_main_view` — Verifies preset changes made through the shared app model survive the later `getInitialView()` path instead of being reset by a new `RugbyGameModel`.
- `tests/Test_RugbyTeamIdentitySupport.mc::test_teamIdentitySupport_normalizes_invalid_mode` — Verifies invalid team-label modes normalize back to the default `Home / Away` preset.
- `tests/Test_RugbyTeamIdentitySupport.mc::test_teamIdentitySupport_resolves_labels_for_preset` — Verifies the preset lookup returns the expected short home/away labels.
- `tests/Test_RugbyTeamIdentitySupport.mc::test_teamIdentitySupport_builds_event_description_from_model` — Verifies score/card event descriptions use the resolved active team label.
- `tests/Test_RugbyTeamIdentitySupport.mc::test_teamIdentitySupport_compact_scoreBand_labels` — Verifies the compact label aliases used when the round-watch top band cannot safely fit the full team labels.
- `tests/Test_RugbyMatchProfiles_Settings.mc::test_setTeamLabelMode_promotes_to_custom_and_persists` — Verifies changing the team-label preset promotes a built-in profile to the persisted `Custom` profile and keeps the selected mode.
- `tests/Test_RugbyPersistenceRenderTypes.mc::test_renderer_topBand_safeBounds_and_fit` — Verifies the renderer’s circular safe-area helper and label-fit guard suppress clipping-prone top-band labels.

Status key: Covered = automated unit test present; Partially Covered = test covers some aspects; Planned = test should be added.

Next steps:
- Add UI/behavior/integration tests for Settings and picker flows (FR-001, FR-002, FR-003, FR-005, FR-006, FR-008, FR-009).
- Expand `Test_RugbyMatchProfiles` to assert `matchProfileId` persistence paths and `lastGameType` semantics.
- Keep this file updated as tests are added or requirements change.

Maintainability note:
- Test modules now include file-level purpose preambles so future additions can be routed into the right test file instead of duplicating coverage.
