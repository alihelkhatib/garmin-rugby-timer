using Toybox.Test;
using Toybox.Lang;
using Toybox.Application.Storage;
using Rez.Strings;

/*
Unit tests for one-shot runtime status messaging and invalid restore recovery.

Purpose: verify user-visible runtime failures do not stay silent and malformed
saved snapshots are cleared instead of leaving the app in partial state.
*/
(:test)
function test_statusMessage_is_one_shot(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    var expected = RugbyStrings.load(Rez.Strings.Status_SaveFailed);
    model.setStatusMessage(expected);

    if (model.consumeStatusMessage() != expected) {
        logger.error("status message did not round-trip");
        return false;
    }
    return model.consumeStatusMessage() == null;
}

(:test)
function test_invalidSavedSnapshot_is_cleared_and_reported(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    Storage.setValue(STORAGE_KEY_GAME_STATE_DATA, {
        "homeScore" => "bad",
        "awayScore" => 3,
        "homeTries" => 1,
        "awayTries" => 0,
        "halfNumber" => 1,
        "gameTime" => 50,
        "elapsedTime" => 55,
        "countdownTimer" => 2400,
        "gameState" => STATE_PLAYING
    });

    var model = new RugbyGameModel();
    model.initialize();

    if (model.gameState != STATE_IDLE) {
        logger.error("invalid snapshot should reset to STATE_IDLE");
        return false;
    }
    if (model.consumeStatusMessage() != RugbyStrings.load(Rez.Strings.Status_SavedMatchReset)) {
        logger.error("invalid snapshot should surface reset message");
        return false;
    }
    return Storage.getValue(STORAGE_KEY_GAME_STATE_DATA) == null;
}
