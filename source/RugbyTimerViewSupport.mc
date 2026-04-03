using Toybox.Lang;

const VIEW_HINT_MODE_NONE = "none";
const VIEW_HINT_MODE_LOCKED = "locked";
const VIEW_HINT_MODE_IDLE = "idle";
const VIEW_HINT_MODE_PLAYING = "playing";

/**
 * Pure presentation rules for the main match view.
 *
 * Purpose: keep overlay-visibility, toast-visibility, and hint-mode decisions
 * out of `RugbyTimerView` so those rules can be unit-tested without WatchUi.
 */
class RugbyTimerViewSupport {
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
