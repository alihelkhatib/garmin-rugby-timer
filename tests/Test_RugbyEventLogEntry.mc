using Toybox.Test;
using Toybox.Lang;

/*
Unit tests for event-log payload formatting and round-trip behavior.

Purpose: verify `RugbyTimerEventLog` preserves stored values and emits the
human-readable strings expected by the log viewer/export path.
*/
(:test)
function test_eventLogEntry_roundtrip_and_display(logger as Test.Logger) as Lang.Boolean {
    var raw = RugbyTimerEventLog.createStoredEntry("01:23", "Home Try");
    return RugbyTimerEventLog.formatStoredEntry(raw) == "01:23 – Home Try";
}

(:test)
function test_eventLogEntry_legacy_payload_is_supported(logger as Test.Logger) as Lang.Boolean {
    var legacy = {
        :time => "01:23",
        :desc => "Home Try"
    };
    return RugbyTimerEventLog.formatStoredEntry(legacy) == "01:23 – Home Try";
}
