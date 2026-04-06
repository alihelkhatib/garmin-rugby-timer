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
    var layout = RugbyRenderLayout.create(10, 20, 30, 40, 50, 60, 70, 80);
    var cardInfo = RugbyRenderedCardInfo.create(2, 12, 100);
    var content = RugbyMainContentLayout.create(120, 140, 160, 18);
    var update = RugbyTimerUpdateResult.create([], true);
    return fonts.countdownFont == 5 && layout.cardsY == 50 && cardInfo.rows == 2 && content.hintLineGap == 18 && update.expired == true;
}

(:test)
function test_renderer_topBand_safeBounds_and_fit(logger as Test.Logger) as Lang.Boolean {
    var safe = RugbyTimerRenderer.getCircleSafeBounds(260, 260, 18, 12);
    if (safe.left >= safe.right) { logger.error("safe bounds should be ordered"); return false; }
    if (!RugbyTimerRenderer.canFitScoreLabel("A", 65, safe.left, 105, true)) { logger.error("single-char label should fit"); return false; }
    return !RugbyTimerRenderer.canFitScoreLabel("VeryLongLabel", 65, safe.left, 105, false);
}
