using Toybox.Test;
using Toybox.Lang;

/*
Storage payload validation tests.

Purpose: catch unsupported Garmin Storage shapes before they escape into live
autosave flows on device.
*/
(:test)
function test_storageSupport_flags_symbol_value_paths(logger as Test.Logger) as Lang.Boolean {
    var payload = {
        "lastEvents" => [
            {
                "type" => :try,
                "home" => true
            }
        ]
    };
    var badPath = RugbyStorageSupport.findUnsupportedValuePath(payload, "gameStateData");
    if (badPath == null) {
        logger.error("symbol payload should be rejected");
        return false;
    }
    return badPath == "gameStateData.lastEvents[0].type";
}

(:test)
function test_storageSupport_accepts_current_snapshot_shapes(logger as Test.Logger) as Lang.Boolean {
    var payload = {
        "lastEvents" => [
            ScoreEvent.create(:conversion, true).toDict()
        ],
        "eventLogEntries" => [
            EventLogEntry.create("01:23", "Home Try").toDict()
        ],
        "yellowHomeTimes" => [
            CardEntry.createFromStartTime(100, 600, "Y1", 1).toDict()
        ]
    };
    return RugbyStorageSupport.findUnsupportedValuePath(payload, "gameStateData") == null;
}

(:test)
function test_storageSupport_accepts_real_built_snapshot(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_PLAYING;
    model.lastUpdate = 1000;
    model.gameTime = 30;
    model.elapsedTime = 30;
    model.suspensionTime = 30;
    model.recordTry(true);
    model.recordPenalty(false);
    model.recordYellowCard(true);

    var snapshot = RugbyTimerPersistence.buildSnapshot(model);
    if (snapshot == null) {
        logger.error("snapshot missing");
        return false;
    }
    return RugbyStorageSupport.findUnsupportedValuePath(snapshot.toDict(), "gameStateData") == null;
}
