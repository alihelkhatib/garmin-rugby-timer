using Toybox.Test;
using Toybox.Lang;
using Toybox.System;
using Toybox.Application.Storage;

/*
Unit tests for match snapshot persistence and restore flows.

Purpose: verify save/restore/finalize behavior for live matches, card state,
and summary persistence after the persistence refactors.
*/
(:test)
function test_recordYellowCard_pauses_live_match_and_tracks_totals(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_PLAYING;
    model.lastUpdate = System.getTimer();
    model.suspensionTime = 75;

    model.recordYellowCard(true);

    if (model.gameState != STATE_PAUSED) { logger.error("yellow card should pause live play"); return false; }
    if (model.pausedState != STATE_PLAYING) { logger.error("pausedState should preserve previous live state"); return false; }
    if (model.yellowHomeTotal != 1) { logger.error("yellowHomeTotal should increment"); return false; }
    if (model.yellowHomeTimes.size() != 1) { logger.error("yellowHomeTimes should contain one active timer"); return false; }

    var yellowTimes = model.yellowHomeTimes;
    var first = CardEntry.fromDict(yellowTimes.remove(0));
    return first != null && first.label == "Y1" && first.duration == model.getYellowCardDuration();
}

(:test)
function test_saveState_restores_playing_match_as_paused_snapshot(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.homeScore = 12;
    model.awayScore = 5;
    model.gameState = STATE_PLAYING;
    model.countdownTimer = 2400;
    model.gameTime = 120;
    model.elapsedTime = 135;
    model.suspensionTime = 140;
    model.lastUpdate = System.getTimer();
    model.yellowHomeTimes = [
        RugbyTimerCards.createYellowCardEntryFromStartTime(100, 600, "Y1", 1)
    ];
    model.yellowHomeLabelCounter = 1;
    model.yellowHomeTotal = 1;

    RugbyTimerPersistence.saveState(model);

    var restored = new RugbyGameModel();
    restored.initialize();

    if (restored.gameState != STATE_PAUSED) { logger.error("restored live match should reopen paused"); return false; }
    if (restored.pausedState != STATE_PLAYING) { logger.error("pausedState should preserve STATE_PLAYING"); return false; }
    if (restored.homeScore != 12 || restored.awayScore != 5) { logger.error("scores did not restore"); return false; }
    if (restored.yellowHomeTimes.size() != 1) { logger.error("yellow timer did not restore"); return false; }
    if (restored.yellowHomeLabelCounter != 1 || restored.yellowHomeTotal != 1) { logger.error("yellow counters did not restore"); return false; }
    if (restored.lastUpdate != null) { logger.error("paused snapshot should not resume ticking immediately"); return false; }

    return true;
}

(:test)
function test_buildSnapshot_and_applySnapshot_roundtrip_core_fields(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.homeScore = 17;
    model.awayScore = 10;
    model.homeTries = 3;
    model.awayTries = 2;
    model.gameState = STATE_PLAYING;
    model.pausedState = null;
    model.countdownTimer = 2400;
    model.gameTime = 300;
    model.elapsedTime = 320;
    model.suspensionTime = 330;
    model.countdownSeconds = 25;
    model.lastUpdate = System.getTimer();
    model.matchProfileId = "15s";
    model.useConversionTimer = true;
    model.usePenaltyTimer = true;
    model.yellowHomeTimes = [
        RugbyTimerCards.createYellowCardEntryFromStartTime(100, 600, "Y1", 1)
    ];
    model.yellowHomeLabelCounter = 1;
    model.yellowHomeTotal = 1;

    var snapshot = RugbyTimerPersistence.buildSnapshot(model);
    if (snapshot == null) { logger.error("buildSnapshot should return a snapshot"); return false; }

    var restored = new RugbyGameModel();
    restored.initialize();
    restored.resetMatchRuntimeState();
    RugbyTimerPersistence.applySnapshot(restored, snapshot, System.getTimer());

    if (restored.homeScore != 17 || restored.awayScore != 10) { logger.error("scores did not roundtrip"); return false; }
    if (restored.homeTries != 3 || restored.awayTries != 2) { logger.error("tries did not roundtrip"); return false; }
    if (restored.gameState != STATE_PAUSED) { logger.error("live snapshot should restore as paused"); return false; }
    if (restored.pausedState != STATE_PLAYING) { logger.error("pausedState should preserve playing"); return false; }
    if (restored.yellowHomeTimes.size() != 1) { logger.error("yellow card timers did not roundtrip"); return false; }
    return restored.yellowHomeLabelCounter == 1 && restored.yellowHomeTotal == 1;
}

(:test)
function test_finalizeGameData_writes_summary_and_event_log(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.homeScore = 21;
    model.awayScore = 14;
    model.teamLabelMode = TEAM_LABEL_MODE_LIGHT_DARK;
    model.yellowHomeTotal = 1;
    model.redAwayTotal = 1;
    model.eventLogEntries = [
        { "time" => "00:10", "description" => "Light Try" } as Lang.Dictionary
    ];

    RugbyTimerPersistence.finalizeGameData(model);

    var summary = MatchSummaryEntry.fromDict(Storage.getValue(STORAGE_KEY_LAST_GAME_SUMMARY));
    if (summary == null) { logger.error("lastGameSummary not written"); return false; }
    if (summary.homeScore != 21 || summary.awayScore != 14) { logger.error("summary scores mismatch"); return false; }
    if (summary.yellowHomeTotal != 1 || summary.redAwayTotal != 1) { logger.error("summary totals mismatch"); return false; }
    if (summary.homeTeamLabel != "Light" || summary.awayTeamLabel != "Dark") { logger.error("summary team labels mismatch"); return false; }

    var eventLog = summary.eventLog as Lang.String;
    return eventLog != null && eventLog.find("Light Try") != null;
}
