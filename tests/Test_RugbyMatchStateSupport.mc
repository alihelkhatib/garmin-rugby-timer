using Toybox.Test;
using Toybox.Lang;

/*
Unit tests for pure match-state transition rules.

Purpose: keep the shared state-classification and next-action helpers covered
so refactors in clock/scoring/delegate/persistence paths stay behavior-safe.
*/
(:test)
function test_matchStateSupport_clock_classification(logger as Test.Logger) as Lang.Boolean {
    if (!RugbyMatchStateSupport.isMainClockRunning(STATE_PLAYING)) { logger.error("playing should run main clock"); return false; }
    if (!RugbyMatchStateSupport.isMainClockRunning(STATE_CONVERSION)) { logger.error("conversion should run main clock"); return false; }
    if (RugbyMatchStateSupport.isMainClockRunning(STATE_HALFTIME)) { logger.error("halftime should not run main clock"); return false; }
    return RugbyMatchStateSupport.isSuspensionClockRunning(STATE_HALFTIME);
}

(:test)
function test_matchStateSupport_restore_and_resume_rules(logger as Test.Logger) as Lang.Boolean {
    if (!RugbyMatchStateSupport.shouldRestoreAsPaused(STATE_PLAYING)) { logger.error("playing should restore paused"); return false; }
    if (RugbyMatchStateSupport.shouldRestoreAsPaused(STATE_HALFTIME)) { logger.error("halftime should not restore paused"); return false; }
    if (RugbyMatchStateSupport.getResumeState(null) != STATE_PLAYING) { logger.error("null pausedState should resume to playing"); return false; }
    return RugbyMatchStateSupport.getRestoredPausedState(STATE_KICKOFF, null) == STATE_PLAYING;
}

(:test)
function test_matchStateSupport_select_action_and_special_timers(logger as Test.Logger) as Lang.Boolean {
    if (RugbyMatchStateSupport.getSelectAction(STATE_IDLE) != :start_game) { logger.error("idle select action mismatch"); return false; }
    if (RugbyMatchStateSupport.getSelectAction(STATE_PAUSED) != :resume_clock) { logger.error("paused select action mismatch"); return false; }
    if (!RugbyMatchStateSupport.shouldStartConversionAfterTry(STATE_PLAYING, true)) { logger.error("playing try should start conversion when enabled"); return false; }
    return RugbyMatchStateSupport.shouldStartPenaltyAfterKick(STATE_PLAYING, false) == false;
}

(:test)
function test_matchIntegrity_reconcile_idle_restores_config_owned_fields(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_IDLE;
    model.halfDuration = 35 * 60;
    model.countdownTimer = 0;
    model.countdownRemaining = 0;
    model.countdownSeconds = 90;
    model.gameTime = 123;
    model.elapsedTime = 456;

    RugbyMatchIntegritySupport.reconcileModelState(model);

    if (model.countdownTimer != 35 * 60) { logger.error("idle countdownTimer should follow halfDuration"); return false; }
    if (model.countdownRemaining != 35 * 60) { logger.error("idle countdownRemaining should follow halfDuration"); return false; }
    if (model.countdownSeconds != 0) { logger.error("idle should clear special countdown"); return false; }
    if (model.gameTime != 0 || model.elapsedTime != 0) { logger.error("idle should reset live clocks"); return false; }
    return model.pausedState == null;
}

(:test)
function test_matchIntegrity_reconcile_invalid_state_falls_back_to_idle(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = 99;
    model.halfDuration = 0;

    RugbyMatchIntegritySupport.reconcileModelState(model);

    if (model.gameState != STATE_IDLE) { logger.error("unknown state should reset to idle"); return false; }
    if (model.halfDuration <= 0) { logger.error("idle fallback should restore positive half duration"); return false; }
    return model.countdownRemaining == model.halfDuration;
}
