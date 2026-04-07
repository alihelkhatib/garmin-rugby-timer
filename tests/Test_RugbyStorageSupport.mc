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
