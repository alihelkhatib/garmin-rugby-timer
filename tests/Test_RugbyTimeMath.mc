using Toybox.Lang;
using Toybox.Test;

/*
Unit tests for shared time-math helpers.

Purpose: verify the centralized snapshot/delta/countdown helpers used by the
runtime update loop, pause sync path, and persistence logic.
*/
(:test)
function test_getDeltaSeconds_clamps_negative(logger as Test.Logger) as Lang.Boolean {
    var delta = RugbyTimeMath.getDeltaSeconds(5000, 4000);
    logger.debug("getDeltaSeconds(5000, 4000) -> " + delta.toString());
    return delta == 0;
}

(:test)
function test_snapshotForwardClock_advances_running_value(logger as Test.Logger) as Lang.Boolean {
    var snapshot = RugbyTimeMath.snapshotForwardClock(10, 1000, 3500, true);
    logger.debug("snapshotForwardClock -> " + snapshot.toString());
    return snapshot >= 12.4 && snapshot <= 12.6;
}

(:test)
function test_snapshotReverseClock_clamps_to_zero(logger as Test.Logger) as Lang.Boolean {
    var snapshot = RugbyTimeMath.snapshotReverseClock(1, 1000, 4000, true);
    logger.debug("snapshotReverseClock -> " + snapshot.toString());
    return snapshot == 0;
}

(:test)
function test_formatShortTime_zero_and_normal(logger as Test.Logger) as Lang.Boolean {
    var zero = RugbyTimeMath.formatShortTime(0);
    var normal = RugbyTimeMath.formatShortTime(125);
    logger.debug("formatShortTime(0) -> " + zero + ", formatShortTime(125) -> " + normal);
    return zero == "--" && normal == "2:05";
}
