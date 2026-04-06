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
