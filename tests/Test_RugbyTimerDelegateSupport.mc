using Toybox.Test;
using Toybox.Lang;
using Toybox.WatchUi;

/*
Unit tests for pure `RugbyTimerDelegate` input helpers.

Purpose: keep button-routing and idle-adjustment rules covered without a live
WatchUi delegate environment.
*/
(:test)
function test_delegateSupport_idleMinuteAdjustment_clamps(logger as Test.Logger) as Lang.Boolean {
    if (RugbyTimerInputSupport.getAdjustedIdleMinutes(60, -1) != 1) { logger.error("low clamp failed"); return false; }
    if (RugbyTimerInputSupport.getAdjustedIdleMinutes(99 * 60, 1) != 99) { logger.error("high clamp failed"); return false; }
    return RugbyTimerInputSupport.getAdjustedIdleMinutes(40 * 60, 1) == 41;
}

(:test)
function test_delegateSupport_halftimeBreakAdjustment_clamps(logger as Test.Logger) as Lang.Boolean {
    if (RugbyTimerInputSupport.getAdjustedBreakSeconds(30, -1) != 0) { logger.error("break low clamp failed"); return false; }
    if (RugbyTimerInputSupport.getAdjustedBreakSeconds(99 * 60, 1) != 99 * 60) { logger.error("break high clamp failed"); return false; }
    return RugbyTimerInputSupport.getAdjustedBreakSeconds(75, 1) == 180;
}

(:test)
function test_delegateSupport_overlayKeyMapping(logger as Test.Logger) as Lang.Boolean {
    if (RugbyTimerInputSupport.getOverlayActionForKey(STATE_CONVERSION, WatchUi.KEY_DOWN) != :miss) { logger.error("conversion down failed"); return false; }
    if (RugbyTimerInputSupport.getOverlayActionForKey(STATE_CONVERSION, WatchUi.KEY_MENU) != :made) { logger.error("conversion menu failed"); return false; }
    if (RugbyTimerInputSupport.getOverlayActionForKey(STATE_PENALTY, WatchUi.KEY_DOWN) != :hide) { logger.error("penalty down failed"); return false; }
    return RugbyTimerInputSupport.getOverlayActionForKey(STATE_PLAYING, WatchUi.KEY_DOWN) == null;
}

(:test)
function test_delegateSupport_presetHoldKeys(logger as Test.Logger) as Lang.Boolean {
    if (!RugbyTimerInputSupport.shouldStartPresetHold(WatchUi.KEY_MENU)) { logger.error("menu should arm hold"); return false; }
    if (!RugbyTimerInputSupport.shouldStartPresetHold(WatchUi.KEY_UP)) { logger.error("up should arm hold"); return false; }
    return RugbyTimerInputSupport.shouldStartPresetHold(WatchUi.KEY_DOWN) == false;
}
