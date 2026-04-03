using Toybox.System;
using Toybox.Lang;

class Assert {
    static var passCount = 0;
    static var failCount = 0;

    static function assertEquals(expected, actual, id as Lang.String) {
        var ok = false;
        try {
            if (expected == actual) {
                ok = true;
            } else if (expected != null && actual != null && expected.toString() == actual.toString()) {
                ok = true;
            }
        } catch (ex) {
            ok = false;
        }
        if (ok) {
            passCount = passCount + 1;
            System.println("[PASS] " + id);
        } else {
            failCount = failCount + 1;
            System.println("[FAIL] " + id + " expected: " + (expected == null ? "null" : expected.toString()) + " actual: " + (actual == null ? "null" : actual.toString()));
        }
    }

    static function assertTrue(expr, id as Lang.String) {
        if (expr) {
            passCount = passCount + 1;
            System.println("[PASS] " + id);
        } else {
            failCount = failCount + 1;
            System.println("[FAIL] " + id + " expected true");
        }
    }

    static function assertFalse(expr, id as Lang.String) {
        if (!expr) {
            passCount = passCount + 1;
            System.println("[PASS] " + id);
        } else {
            failCount = failCount + 1;
            System.println("[FAIL] " + id + " expected false");
        }
    }

    static function summary() {
        System.println("TEST SUMMARY: PASS=" + passCount.toString() + " FAIL=" + failCount.toString());
        if (failCount > 0) {
            System.println("TESTS FAILED");
        } else {
            System.println("TESTS PASSED");
        }
    }
}
