using Toybox.System;
using Toybox.Lang;
using Toybox.Test;

// Purpose: verify live remaining calculation for an actively running card entry.
(:test)
function test_getEntryRemaining_live(logger as Test.Logger) as Lang.Boolean {
    var entry1 = { "startTime" => 10, "duration" => 30 } as Lang.Dictionary;
    var rem1 = RugbyTimerCards.getEntryRemaining(entry1, 15);
    logger.debug("getEntryRemaining live -> " + rem1.toString());
    return rem1 == 25;
}

// Purpose: verify stored 'remaining' value is used when startTime/clock are unavailable.
(:test)
function test_getEntryRemaining_stored(logger as Test.Logger) as Lang.Boolean {
    var entry2 = { "remaining" => 20, "duration" => 60 } as Lang.Dictionary;
    var rem2 = RugbyTimerCards.getEntryRemaining(entry2, null);
    logger.debug("getEntryRemaining stored -> " + rem2.toString());
    return rem2 == 20;
}

// Purpose: exercise `updateYellowTimers` path and verify it returns one updated timer with positive remaining.
(:test)
function test_updateYellowTimers_basic(logger as Test.Logger) as Lang.Boolean {
    var list = [];
    list.add({ "startTime" => 0, "duration" => 60 } as Lang.Dictionary);
    var res = RugbyTimerCards.updateYellowTimers(null, list, 10);
    var timers = res["timers"] as Lang.Array;
    logger.debug("updateYellowTimers timers size: " + timers.size().toString());
    if (timers.size() != 1) { return false; }
    var rem3 = timers[0]["remaining"];
    logger.debug("updateYellowTimers remaining[0] -> " + rem3.toString());
    return rem3 > 0;
}
