using Toybox.Test;
using Toybox.Lang;
using Toybox.Application;
using Toybox.WatchUi;

/*
Unit tests for `RugbyTimerDelegate` input rules and delegate hot paths.

Purpose: keep button-routing and idle-adjustment rules covered with mostly
headless helpers, plus one real-delegate idle regression path.
*/

class TestDelegateView {
    var isLocked;
    var actionAllowed;

    function initialize() {
        isLocked = false;
        actionAllowed = false;
    }

    function isActionAllowed() {
        return actionAllowed;
    }

    function isSpecialOverlayActive() {
        return false;
    }

    function closeSpecialTimerScreen() {
    }

    function showCardDialog() {
    }

    function showScoreDialog() {
    }
}
(:test)
function test_delegateSupport_idleMinuteAdjustment_clamps(logger as Test.Logger) as Lang.Boolean {
    if (RugbyTimerInputSupport.getAdjustedIdleMinutes(60, -1) != 1) { logger.error("low clamp failed"); return false; }
    if (RugbyTimerInputSupport.getAdjustedIdleMinutes(99 * 60, 1) != 99) { logger.error("high clamp failed"); return false; }
    return RugbyTimerInputSupport.getAdjustedIdleMinutes(40 * 60, 1) == 41;
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

(:test)
function test_delegate_idle_keys_adjust_without_action_gate(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    var app = Application.getApp() as TestRunnerApp;
    app.rugbyView = new TestDelegateView();

    var delegate = new RugbyTimerDelegate(model);
    var downHandled = delegate.onNextPage();
    if (!downHandled || model.countdownTimer != 39 * 60) {
        logger.error("idle next-page should shorten immediately even when action gate is closed");
        return false;
    }

    var upHandled = delegate.onPreviousPage();
    return upHandled && model.countdownTimer == 40 * 60;
}
