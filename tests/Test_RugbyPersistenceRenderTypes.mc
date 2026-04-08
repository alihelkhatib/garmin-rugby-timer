using Toybox.Test;
using Toybox.Lang;
using Toybox.Graphics;

/*
Unit tests for the persistence layer and small typed helpers.

Purpose: ensure storage adapters still round-trip and the surviving typed
presentation wrappers behave as expected after removing the old geometry types.
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
function test_smallRenderTypes_and_timerUpdateResult(logger as Test.Logger) as Lang.Boolean {
    var card = RugbyCardSlotPresentation.create("Y1", "9:59", Graphics.COLOR_YELLOW, true);
    var update = RugbyTimerUpdateResult.create([], true);
    return card.label == "Y1"
        && card.value == "9:59"
        && card.color == Graphics.COLOR_YELLOW
        && card.visible == true
        && update.expired == true;
}
