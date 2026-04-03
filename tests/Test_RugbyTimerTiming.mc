using Toybox.System;
using Toybox.Lang;

class Test_RugbyTimerTiming {
    static function run() {
        // formatTime tests
        Assert.assertEquals("01:05", RugbyTimerTiming.formatTime(65), "formatTime 65s");
        Assert.assertEquals("00:00", RugbyTimerTiming.formatTime(-1), "formatTime negative");

        // getDisplayCountdownSeconds should be >= input and handle null/negative
        var v = RugbyTimerTiming.getDisplayCountdownSeconds(5);
        Assert.assertTrue(v >= 5, "getDisplayCountdownSeconds >= input");
        var v2 = RugbyTimerTiming.getDisplayCountdownSeconds(null);
        Assert.assertEquals(0, v2, "getDisplayCountdownSeconds null -> 0");
    }
}
