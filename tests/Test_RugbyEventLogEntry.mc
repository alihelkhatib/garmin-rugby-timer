using Toybox.Test;
using Toybox.Lang;

/*
Unit tests for EventLogEntry formatting and round-trip behavior.

Purpose: verify the typed event-log wrapper preserves stored values and emits
the human-readable strings expected by the log viewer/export path.
*/
(:test)
function test_eventLogEntry_roundtrip_and_display(logger as Test.Logger) as Lang.Boolean {
    var raw = EventLogEntry.create("01:23", "Home Try").toDict();
    var entry = EventLogEntry.fromDict(raw);
    if (entry == null) { logger.error("EventLogEntry.fromDict returned null"); return false; }
    return entry.toDisplayString() == "01:23 – Home Try";
}
