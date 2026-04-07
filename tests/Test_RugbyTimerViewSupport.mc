using Toybox.Test;
using Toybox.Lang;

/*
Unit tests for the pure `RugbyTimerViewSupport` presentation rules.

Purpose: keep the extracted view-only decisions covered without needing a live
WatchUi device context.
*/
(:test)
function test_viewSupport_overlayVisibility_rules(logger as Test.Logger) as Lang.Boolean {
    if (!RugbyTimerViewSupport.getOverlayVisibility(false, STATE_CONVERSION)) {
        logger.error("conversion should force overlay visible");
        return false;
    }
    if (!RugbyTimerViewSupport.getOverlayVisibility(true, STATE_PENALTY)) {
        logger.error("penalty should preserve existing overlay visibility");
        return false;
    }
    return !RugbyTimerViewSupport.getOverlayVisibility(true, STATE_PLAYING);
}

(:test)
function test_viewSupport_hintMode_rules(logger as Test.Logger) as Lang.Boolean {
    if (RugbyTimerViewSupport.getHintMode(true, STATE_PLAYING) != VIEW_HINT_MODE_LOCKED) {
        logger.error("locked hint mode mismatch");
        return false;
    }
    if (RugbyTimerViewSupport.getHintMode(false, STATE_IDLE) != VIEW_HINT_MODE_IDLE) {
        logger.error("idle hint mode mismatch");
        return false;
    }
    if (RugbyTimerViewSupport.getHintMode(false, STATE_PLAYING) != VIEW_HINT_MODE_PLAYING) {
        logger.error("playing hint mode mismatch");
        return false;
    }
    if (RugbyTimerViewSupport.getHintMode(false, STATE_HALFTIME) != VIEW_HINT_MODE_HALFTIME) {
        logger.error("halftime hint mode mismatch");
        return false;
    }
    return RugbyTimerViewSupport.getHintMode(false, STATE_PAUSED) == VIEW_HINT_MODE_NONE;
}

(:test)
function test_viewSupport_toast_visibility_rules(logger as Test.Logger) as Lang.Boolean {
    if (!RugbyTimerViewSupport.shouldShowToast(false, "Saved", 100, 50)) {
        logger.error("toast should show while active");
        return false;
    }
    if (RugbyTimerViewSupport.shouldShowToast(true, "Saved", 100, 50)) {
        logger.error("toast should not show during overlay");
        return false;
    }
    if (RugbyTimerViewSupport.shouldShowToast(false, null, 100, 50)) {
        logger.error("toast should not show with null message");
        return false;
    }
    return !RugbyTimerViewSupport.shouldShowToast(false, "Saved", 50, 100);
}

(:test)
function test_renderer_mainCountdown_uses_half_duration_while_idle(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_IDLE;
    model.halfDuration = 41 * 60;
    model.countdownTimer = 0;
    model.gameTime = 999;

    return RugbyTimerViewSupport.getMainCountdownSeconds(model, 0) == 41 * 60;
}

(:test)
function test_viewSupport_idleConfiguredSeconds_prefers_profile_config_and_safe_fallback(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.halfDuration = 40 * 60;
    model.countdownTimer = 25 * 60;
    model.countdownRemaining = 35 * 60;
    if (RugbyTimerViewSupport.getConfiguredIdleSeconds(model) != 40 * 60) {
        logger.error("idle configured seconds should prefer halfDuration");
        return false;
    }
    model.countdownRemaining = 0;
    model.halfDuration = 0;
    if (RugbyTimerViewSupport.getConfiguredIdleSeconds(model) != 25 * 60) {
        logger.error("idle configured seconds should fall back to countdownTimer");
        return false;
    }
    model.countdownTimer = 0;
    if (RugbyTimerViewSupport.getConfiguredIdleSeconds(model) != 35 * 60) {
        logger.error("idle configured seconds should fall back to remaining time only when config is unavailable");
        return false;
    }
    model.countdownRemaining = 0;
    model.is7s = true;
    return RugbyTimerViewSupport.getConfiguredIdleSeconds(model) == 420;
}

(:test)
function test_viewSupport_mainCountdown_uses_halftime_break_then_half_duration(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_HALFTIME;
    model.halfDuration = 40 * 60;
    model.countdownSeconds = 90;
    model.lastUpdate = 0;

    if (RugbyTimerViewSupport.getMainCountdownSeconds(model, 30000) >= 90) {
        logger.error("halftime break countdown should tick down while active");
        return false;
    }

    model.countdownSeconds = 0;
    return RugbyTimerViewSupport.getMainCountdownSeconds(model, 30000) == 40 * 60;
}

(:test)
function test_viewSupport_special_and_suspension_clocks_share_snapshot_math(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.lastUpdate = 0;
    model.gameState = STATE_CONVERSION;
    model.countdownSeconds = 30;
    model.suspensionTime = 10;

    var special = RugbyTimerViewSupport.getSpecialCountdownSeconds(model, 4000);
    var suspension = RugbyTimerViewSupport.getSuspensionClockSeconds(model, 4000);
    if (special >= 30) {
        logger.error("special countdown should tick down");
        return false;
    }
    return suspension > 10;
}
