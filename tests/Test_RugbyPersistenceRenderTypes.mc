using Toybox.Test;
using Toybox.Lang;

/*
Unit tests for the persistence/render typed adapter layer.

Purpose: ensure the new wrappers round-trip the older dictionary schemas
without changing storage or render-boundary behavior.
*/
(:test)
function test_persistedCardTimerEntry_roundtrip(logger as Test.Logger) as Lang.Boolean {
    var entry = PersistedCardTimerEntry.create(600, 100, 590, "Y1", 1, true);
    var restored = PersistedCardTimerEntry.fromDict(entry.toDict());
    if (restored == null) { logger.error("PersistedCardTimerEntry restore failed"); return false; }
    return restored.label == "Y1" && restored.cardId == 1 && restored.vibeTriggered == true;
}

(:test)
function test_persistedGameSnapshot_roundtrip(logger as Test.Logger) as Lang.Boolean {
    var snapshot = new PersistedGameSnapshot();
    snapshot.homeScore = 10;
    snapshot.awayScore = 5;
    snapshot.gameState = STATE_PAUSED;
    snapshot.pausedState = STATE_PLAYING;
    snapshot.matchProfileId = "15s";
    var restored = PersistedGameSnapshot.fromDict(snapshot.toDict());
    if (restored == null) { logger.error("PersistedGameSnapshot restore failed"); return false; }
    return restored.homeScore == 10 && restored.pausedState == STATE_PLAYING;
}

(:test)
function test_renderTypes_and_timerUpdateResult(logger as Test.Logger) as Lang.Boolean {
    var fonts = RugbyRenderFonts.create(1, 2, 3, 4, 5, 6, 7);
    var layout = RugbyRenderLayout.create();
    layout.family = "compact_round";
    layout.safeTop = 10;
    layout.teamLabelY = 20;
    layout.scoreY = 30;
    layout.homeTriesX = 15;
    layout.awayTriesX = 85;
    layout.cardsY = 50;
    layout.stateBaseY = 60;
    layout.hintBaseY = 70;
    layout.iconY = 80;
    layout.showIcons = true;
    layout.showElapsedTimer = true;
    layout.showTries = true;
    var cardInfo = RugbyRenderedCardInfo.create(2, 12, 100);
    var content = RugbyMainContentLayout.create(120, 140, 160, 18);
    var update = RugbyTimerUpdateResult.create([], true);
    return fonts.countdownFont == 5 && layout.family == "compact_round" && layout.homeTriesX == 15 && layout.showTries == true && layout.cardsY == 50 && cardInfo.rows == 2 && content.hintLineGap == 18 && update.expired == true;
}
