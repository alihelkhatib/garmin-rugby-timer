// Tests for RugbyTimerTiming
// Each test below includes a short purpose comment describing intent and expectations.
using Toybox.System;
using Toybox.Lang;
using Toybox.Test;

// Purpose: verifies `formatTime` formats seconds into MM:SS correctly (65 -> "01:05").
(:test)
function test_formatTime_65(logger as Test.Logger) as Lang.Boolean {
    var got = RugbyTimerTiming.formatTime(65);
    logger.debug("formatTime(65) -> " + got);
    return got == "01:05";
}

// Purpose: verifies `formatTime` clamps negative inputs to "00:00".
(:test)
function test_formatTime_negative(logger as Test.Logger) as Lang.Boolean {
    var got = RugbyTimerTiming.formatTime(-1);
    logger.debug("formatTime(-1) -> " + got);
    return got == "00:00";
}

// Purpose: ensures `getDisplayCountdownSeconds` returns a value >= input for normal numeric inputs.
(:test)
function test_getDisplayCountdownSeconds_nonnull(logger as Test.Logger) as Lang.Boolean {
    var v = RugbyTimerTiming.getDisplayCountdownSeconds(5);
    logger.debug("getDisplayCountdownSeconds(5) -> " + v.toString());
    return v >= 5;
}

// Purpose: ensures `getDisplayCountdownSeconds` returns 0 for null/negative inputs.
(:test)
function test_getDisplayCountdownSeconds_null(logger as Test.Logger) as Lang.Boolean {
    var v2 = RugbyTimerTiming.getDisplayCountdownSeconds(null);
    logger.debug("getDisplayCountdownSeconds(null) -> " + v2.toString());
    return v2 == 0;
}
