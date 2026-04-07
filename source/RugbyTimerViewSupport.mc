using Toybox.Lang;

const VIEW_HINT_MODE_NONE = "none";
const VIEW_HINT_MODE_LOCKED = "locked";
const VIEW_HINT_MODE_IDLE = "idle";
const VIEW_HINT_MODE_PLAYING = "playing";
const VIEW_HINT_MODE_HALFTIME = "halftime";

/**
 * Pure presentation rules for the main match view.
 *
 * Purpose: keep overlay-visibility, toast-visibility, and hint-mode decisions
 * out of `RugbyTimerView` so those rules can be unit-tested without WatchUi.
 */
class RugbyTimerViewSupport {
    static function isHalftimeBreakActive(model) {
        return model != null
            && model.gameState == STATE_HALFTIME
            && RugbyTimeMath.isNumeric(model.countdownSeconds)
            && model.countdownSeconds > 0;
    }

    static function getConfiguredIdleSeconds(model) {
        if (RugbyTimeMath.isNumeric(model.halfDuration) && model.halfDuration > 0) {
            return RugbyTimeMath.normalizeSeconds(model.halfDuration);
        }
        if (RugbyTimeMath.isNumeric(model.countdownTimer) && model.countdownTimer > 0) {
            return RugbyTimeMath.normalizeSeconds(model.countdownTimer);
        }
        if (RugbyTimeMath.isNumeric(model.countdownRemaining) && model.countdownRemaining > 0) {
            return RugbyTimeMath.normalizeSeconds(model.countdownRemaining);
        }
        return RugbyMatchProfiles.getDefaultHalfDuration(model != null && model.is7s == true);
    }

    static function getElapsedSeconds(model, renderNow) {
        return RugbyTimeMath.snapshotForwardClock(
            model.elapsedTime,
            model.lastUpdate,
            renderNow,
            model.gameState != STATE_IDLE && model.gameState != STATE_ENDED
        );
    }

    static function getMainCountdownSeconds(model, renderNow) {
        if (model.gameState == STATE_IDLE) {
            return RugbyTimerViewSupport.getConfiguredIdleSeconds(model);
        }
        if (model.gameState == STATE_HALFTIME) {
            return RugbyTimeMath.normalizeSeconds(model.halfDuration);
        }
        return RugbyTimeMath.getCountdownRemaining(
            model.countdownTimer,
            RugbyTimeMath.snapshotForwardClock(
                model.gameTime,
                model.lastUpdate,
                renderNow,
                RugbyTimerTiming.isClockRunning(model.gameState)
            )
        );
    }

    static function getSpecialCountdownSeconds(model, renderNow) {
        return RugbyTimeMath.snapshotReverseClock(
            model.countdownSeconds,
            model.lastUpdate,
            renderNow,
            model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || RugbyTimerViewSupport.isHalftimeBreakActive(model)
        );
    }

    static function getSuspensionClockSeconds(model, renderNow) {
        return RugbyTimeMath.snapshotForwardClock(
            model.suspensionTime,
            model.lastUpdate,
            renderNow,
            RugbyTimerTiming.isSuspensionClockRunning(model.gameState)
        );
    }

    /**
     * Reconciles the overlay visibility flag with the current match state.
     */
    static function getOverlayVisibility(currentVisible, gameState) {
        if (gameState == STATE_CONVERSION) {
            return true;
        }
        if (gameState == STATE_PENALTY) {
            return currentVisible;
        }
        return false;
    }

    /**
     * Returns the active hint mode for the main match screen.
     */
    static function getHintMode(isLocked, gameState) {
        if (isLocked) {
            return VIEW_HINT_MODE_LOCKED;
        }
        if (gameState == STATE_IDLE) {
            return VIEW_HINT_MODE_IDLE;
        }
        if (gameState == STATE_PLAYING) {
            return VIEW_HINT_MODE_PLAYING;
        }
        if (gameState == STATE_HALFTIME) {
            return VIEW_HINT_MODE_HALFTIME;
        }
        return VIEW_HINT_MODE_NONE;
    }

    /**
     * Guards the non-overlay status toast path.
     */
    static function shouldShowToast(isOverlayActive, message, expiry, now) {
        if (isOverlayActive) {
            return false;
        }
        if (!(message instanceof Lang.String) || message.length() == 0) {
            return false;
        }
        return now < expiry;
    }
}
