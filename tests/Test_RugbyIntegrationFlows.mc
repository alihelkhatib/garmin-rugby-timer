using Toybox.Test;
using Toybox.Lang;
using Toybox.System;
using Toybox.Application.Storage;

/*
Integration-style tests for the main match flows.

Purpose: exercise multi-step model/service behavior in the Garmin unit-test
target so the simulator test build covers the core operational paths.
*/
(:test)
function test_integration_preset_change_persists_and_restores(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.setMatchProfile("7s");
    model.setMatchProfile("u19");

    var restored = new RugbyGameModel();
    restored.initialize();

    return restored.matchProfileId == "u19"
        && restored.halfDuration == 2100
        && restored.useConversionTimer == true
        && restored.usePenaltyTimer == true;
}

(:test)
function test_integration_start_pause_resume_restore_flow(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.startGame();
    if (model.gameState != STATE_PLAYING) {
        logger.error("startGame did not start play");
        return false;
    }

    model.pauseGame();
    if (model.gameState != STATE_PAUSED) {
        logger.error("pauseGame did not pause");
        return false;
    }

    var pausedState = model.pausedState;
    model.persistState();

    var restored = new RugbyGameModel();
    restored.initialize();
    if (restored.gameState != STATE_PAUSED) {
        logger.error("restored game should reopen paused");
        return false;
    }
    if (restored.pausedState != pausedState) {
        logger.error("pausedState was not preserved");
        return false;
    }

    restored.resumeGame();
    return restored.gameState == STATE_PLAYING;
}

(:test)
function test_integration_card_timers_survive_persist_restore(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.is7s = false;
    model.gameState = STATE_PLAYING;
    model.lastUpdate = System.getTimer();
    model.suspensionTime = 200;

    model.recordYellowCard(true);
    model.recordRedCard(false);
    model.suspensionTime = 260;
    model.yellowHomeTimes = RugbyTimerCards.updateYellowTimers(model, model.yellowHomeTimes, model.suspensionTime).timers;
    model.redAwayTimes = RugbyTimerCards.updateYellowTimers(model, model.redAwayTimes, model.suspensionTime).timers;
    model.persistState();

    var restored = new RugbyGameModel();
    restored.initialize();

    if (restored.yellowHomeTimes.size() != 1 || restored.redAwayTimes.size() != 1) {
        logger.error("sanction timers did not restore");
        return false;
    }
    var yellowTimes = restored.yellowHomeTimes;
    var redTimes = restored.redAwayTimes;
    var yellowEntry = CardEntry.fromDict(yellowTimes.remove(0));
    var redEntry = CardEntry.fromDict(redTimes.remove(0));
    if (yellowEntry == null || redEntry == null) {
        logger.error("restored sanction entries malformed");
        return false;
    }
    return yellowEntry.label == "Y1"
        && redEntry.label == "R1"
        && yellowEntry.remaining < yellowEntry.duration
        && redEntry.remaining < redEntry.duration;
}

(:test)
function test_integration_startGame_uses_strict_rugby_recording(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.startGame();

    if (model.gameState != STATE_PLAYING) {
        logger.error("match did not enter playing state");
        return false;
    }

    if (model.session != null) {
        return model.consumeStatusMessage() == null;
    }

    var status = model.consumeStatusMessage();
    if (status == null) {
        logger.error("strict recording path should either start a session or report why it did not");
        return false;
    }
    return status == "Recording unsupported"
        || status == "Rugby sport unsupported"
        || status == "Recording start failed";
}
