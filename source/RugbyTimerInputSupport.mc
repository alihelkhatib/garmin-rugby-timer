using Toybox.WatchUi;

/**
 * Pure helper methods for `RugbyTimerDelegate`.
 *
 * Purpose: keep small but behavior-sensitive input rules testable without
 * requiring a live WatchUi view/delegate environment.
 */
class RugbyTimerInputSupport {
    /**
     * Converts the current countdown timer into a clamped whole-minute value
     * after applying the requested increment/decrement step.
     */
    static function getAdjustedIdleMinutes(countdownTimer, deltaMinutes) {
        var currentMinutes = (countdownTimer / 60).toLong();
        var nextMinutes = currentMinutes + deltaMinutes;
        if (nextMinutes < 1) { return 1; }
        if (nextMinutes > 99) { return 99; }
        return nextMinutes;
    }

    /**
     * Adjusts a halftime break countdown in whole-minute steps while allowing
     * the running timer to reach zero if the referee shortens the break.
     */
    static function getAdjustedBreakSeconds(currentSeconds, deltaMinutes) {
        var currentMinutes = (currentSeconds / 60).toLong();
        if ((currentSeconds % 60) > 0) {
            currentMinutes += 1;
        }
        var nextMinutes = currentMinutes + deltaMinutes;
        if (nextMinutes < 0) { return 0; }
        if (nextMinutes > 99) { return 99 * 60; }
        return nextMinutes * 60;
    }

    /**
     * Maps overlay hardware keys to the logical overlay action the delegate
     * should execute.
     */
    static function getOverlayActionForKey(gameState, key) {
        if (gameState == STATE_CONVERSION) {
            if (key == WatchUi.KEY_DOWN) { return :miss; }
            if (key == WatchUi.KEY_MENU) { return :made; }
        } else if (gameState == STATE_PENALTY) {
            if (key == WatchUi.KEY_DOWN || key == WatchUi.KEY_MENU) { return :hide; }
        }
        return null;
    }

    /**
     * Only MENU and UP can arm the hold-to-preset shortcut.
     */
    static function shouldStartPresetHold(key) {
        return key == WatchUi.KEY_MENU || key == WatchUi.KEY_UP;
    }

}
