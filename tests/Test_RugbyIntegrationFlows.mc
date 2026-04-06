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

(:test)
function test_integration_conversion_made_returns_to_play_and_scores(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_PLAYING;
    model.useConversionTimer = true;

    model.recordTry(true);
    if (model.gameState != STATE_CONVERSION) {
        logger.error("try should enter conversion state");
        return false;
    }
    if (model.conversionTeam != true) {
        logger.error("conversionTeam should track home");
        return false;
    }

    model.handleConversionSuccess();

    if (model.gameState != STATE_PLAYING) {
        logger.error("made conversion should resume play");
        return false;
    }
    if (model.homeScore != 7) {
        logger.error("home score should include try + conversion");
        return false;
    }
    return model.conversionTeam == null;
}

(:test)
function test_integration_conversion_miss_returns_to_play_without_extra_score(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_PLAYING;
    model.useConversionTimer = true;

    model.recordTry(false);
    if (model.gameState != STATE_CONVERSION) {
        logger.error("try should enter conversion state");
        return false;
    }

    model.handleConversionMiss();

    if (model.gameState != STATE_PLAYING) {
        logger.error("missed conversion should resume play");
        return false;
    }
    if (model.awayScore != 5) {
        logger.error("away score should remain try-only after miss");
        return false;
    }
    return model.conversionTeam == null;
}

(:test)
function test_integration_penalty_timer_starts_and_expiry_resumes_play(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_PLAYING;
    model.usePenaltyTimer = true;
    model.penaltyKickTime = 5;

    model.recordPenalty(true);

    if (model.gameState != STATE_PENALTY) {
        logger.error("penalty goal should enter penalty timer state when enabled");
        return false;
    }
    if (model.homeScore != 3 || model.homePenalties != 1) {
        logger.error("penalty scoring totals mismatch");
        return false;
    }

    model.lastUpdate = System.getTimer() - 6000;
    RugbyTimerTiming.updateGame(model);

    return model.gameState == STATE_PLAYING && model.countdownSeconds == 0;
}

(:test)
function test_integration_second_half_then_end_game(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_HALFTIME;
    model.halfNumber = 1;
    model.countdownTimer = 600;
    model.countdownRemaining = 0;

    model.startSecondHalf();

    if (model.gameState != STATE_PLAYING) {
        logger.error("second half should start from halftime");
        return false;
    }
    if (model.halfNumber != 2) {
        logger.error("half number should advance to 2");
        return false;
    }

    model.gameTime = model.countdownTimer;
    model.countdownRemaining = 0;
    model.lastUpdate = System.getTimer();
    model.endGame();

    return model.gameState == STATE_ENDED && model.lastUpdate == null;
}
