using Toybox.System;

class TestRunner {
    static function runAll() {
        System.println("=== TEST RUNNER START ===");
        Test_RugbyTimerTiming.run();
        Test_RugbyTimerCards.run();
        Assert.summary();
        System.println("=== TEST RUNNER END ===");
    }
}
