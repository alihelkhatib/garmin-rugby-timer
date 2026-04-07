using Toybox.Test;
using Toybox.Lang;
using Toybox.Application.Storage;

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
    model.setStatusMessage("Save failed");

    if (model.consumeStatusMessage() != "Save failed") {
        logger.error("status message did not round-trip");
        return false;
    }
    return model.consumeStatusMessage() == null;
}

(:test)
function test_runtimeNotice_wraps_legacy_strings_and_preserves_message(logger as Test.Logger) as Lang.Boolean {
    var notice = RugbyRuntimeNotice.fromValue("Recording unsupported");
    if (notice == null) {
        logger.error("legacy string should normalize to runtime notice");
        return false;
    }
    if (notice.message != "Recording unsupported") {
        logger.error("runtime notice message mismatch");
        return false;
    }
    return notice.channel == RUGBY_NOTICE_CHANNEL_TOAST;
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
    if (model.consumeStatusMessage() != "Saved match reset") {
        logger.error("invalid snapshot should surface reset message");
        return false;
    }
    return Storage.getValue(STORAGE_KEY_GAME_STATE_DATA) == null;
}
