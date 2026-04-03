using Toybox.System;
using Toybox.Lang;

class Test_RugbyTimerCards {
    static function run() {
        // Live entry remaining calculation
        var entry1 = { "startTime" => 10, "duration" => 30 } as Lang.Dictionary;
        var rem1 = RugbyTimerCards.getEntryRemaining(entry1, 15);
        Assert.assertEquals(25, rem1, "getEntryRemaining live");

        // Stored remaining path
        var entry2 = { "remaining" => 20, "duration" => 60 } as Lang.Dictionary;
        var rem2 = RugbyTimerCards.getEntryRemaining(entry2, null);
        Assert.assertEquals(20, rem2, "getEntryRemaining stored");

        // updateYellowTimers basic behavior
        var list = [];
        list.add({ "startTime" => 0, "duration" => 60 } as Lang.Dictionary);
        var res = RugbyTimerCards.updateYellowTimers(null, list, 10);
        var timers = res["timers"] as Lang.Array;
        Assert.assertTrue(timers.size() == 1, "updateYellowTimers returns one timer");
        var rem3 = timers[0]["remaining"];
        Assert.assertTrue(rem3 > 0, "updateYellowTimers remaining positive");
    }
}
