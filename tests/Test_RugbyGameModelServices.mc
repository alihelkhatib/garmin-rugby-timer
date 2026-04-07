using Toybox.Test;
using Toybox.Lang;
using Toybox.System;

/*
Unit tests for the `RugbyGameModel` facade over the extracted services.

Purpose: verify the public model methods still drive the expected clock,
scoring, and persistence behavior after the service split.
*/
(:test)
function test_start_pause_resume_game_wrappers(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    var model = new RugbyGameModel();
    model.initialize();

    model.startGame();
    if (model.gameState != STATE_PLAYING) { logger.error("startGame did not enter STATE_PLAYING"); return false; }

    model.pauseGame();
    if (model.gameState != STATE_PAUSED) { logger.error("pauseGame did not enter STATE_PAUSED"); return false; }

    model.resumeGame();
    return model.gameState == STATE_PLAYING;
}

(:test)
function test_startGame_uses_configured_halfDuration_even_if_countdownTimer_stale(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_IDLE;
    model.halfDuration = 40 * 60;
    model.countdownTimer = 0;
    model.countdownRemaining = 0;
    model.countdownSeconds = 60;

    model.startGame();

    if (model.gameState != STATE_PLAYING) { logger.error("startGame did not enter STATE_PLAYING"); return false; }
    if (model.countdownTimer != 40 * 60) { logger.error("startGame should restore countdownTimer from halfDuration"); return false; }
    if (model.countdownRemaining != 40 * 60) { logger.error("startGame should restore countdownRemaining from halfDuration"); return false; }
    return model.countdownSeconds == 0;
}

(:test)
function test_recordTry_starts_conversion_and_undo_reverts(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_PLAYING;
    model.useConversionTimer = true;

    model.recordTry(true);
    if (model.homeScore != 5 || model.homeTries != 1) { logger.error("try scoring mismatch"); return false; }
    if (model.gameState != STATE_CONVERSION) { logger.error("try should enter conversion state when enabled"); return false; }

    model.gameState = STATE_PLAYING;
    var ok = model.undoLastEvent();
    if (!ok) { logger.error("undoLastEvent returned false"); return false; }
    return model.homeScore == 0 && model.homeTries == 0;
}

(:test)
function test_saveGame_wrapper_writes_summary(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.homeScore = 9;
    model.awayScore = 3;

    model.saveGame();

    var summary = MatchSummaryEntry.fromDict(Toybox.Application.Storage.getValue(STORAGE_KEY_LAST_GAME_SUMMARY));
    if (summary == null) { logger.error("saveGame did not write summary"); return false; }
    return summary.homeScore == 9 && summary.awayScore == 3;
}

(:test)
function test_preset_switching_updates_selected_profile_and_timer(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    model.setMatchProfile("7s");
    if (model.matchProfileId != "7s" || model.halfDuration != 420) { logger.error("7s preset not applied"); return false; }

    model.setMatchProfile("10s");
    if (model.matchProfileId != "10s" || model.halfDuration != 600 || model.conversionTime != 90) { logger.error("10s preset not applied"); return false; }

    model.setMatchProfile("u19");
    return model.matchProfileId == "u19" && model.halfDuration == 2100;
}

(:test)
function test_settings_mutation_order_stays_custom_and_persists_values(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    model.setMatchProfile("15s");
    model.setFormatFamily(true);
    model.setHalfDuration(600);
    model.setConversionTime(45);

    var stored = MatchProfileEntry.fromDict(RugbyMatchProfiles.getStoredCustomProfile());
    if (stored == null) { logger.error("stored custom missing"); return false; }
    return model.matchProfileId == "custom" && stored.halfDuration == 600 && stored.conversionTime == 45 && stored.is7s == true;
}

(:test)
function test_idle_half_duration_change_resets_idle_runtime_fields(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_IDLE;
    model.gameTime = 123;
    model.countdownSeconds = 15;
    model.countdownRemaining = 0;

    model.setHalfDuration(41 * 60);

    if (model.halfDuration != 41 * 60) { logger.error("half duration not updated"); return false; }
    if (model.countdownTimer != 41 * 60) { logger.error("countdown timer not updated"); return false; }
    if (model.countdownRemaining != 41 * 60) { logger.error("idle countdown remaining not reset"); return false; }
    if (model.gameTime != 0) { logger.error("idle game time not reset"); return false; }
    return model.countdownSeconds == 0;
}

(:test)
function test_model_initialize_recovers_from_invalid_custom_idle_profile(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    Toybox.Application.Storage.setValue(STORAGE_KEY_MATCH_PROFILE_ID, "custom");
    Toybox.Application.Storage.setValue(STORAGE_KEY_CUSTOM_HALF_DURATION, 0);
    Toybox.Application.Storage.setValue(STORAGE_KEY_CUSTOM_PROFILE_IS_7S, false);

    var model = new RugbyGameModel();
    model.initialize();

    if (model.gameState != STATE_IDLE) { logger.error("invalid custom profile should still boot idle"); return false; }
    if (model.halfDuration != 2400) { logger.error("invalid custom half duration should recover to 15s"); return false; }
    if (model.countdownTimer != 2400) { logger.error("idle countdown timer should recover to 15s"); return false; }
    return model.countdownRemaining == 2400;
}
