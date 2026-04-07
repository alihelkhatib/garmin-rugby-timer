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
    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_IDLE;
    model.halfDuration = 41 * 60;
    model.countdownTimer = 0;
    model.gameTime = 999;

    return RugbyTimerRenderer.getMainCountdownSeconds(model, 0) == 41 * 60;
}
