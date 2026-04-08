using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Rez.Strings;

/**
 * Special overlay presentation helper for conversion and penalty states.
 *
 * Purpose: keep overlay state/label/hint rules centralized while the view
 * binds them into XML-managed overlay layouts.
 */
class RugbyTimerOverlay {
    static function isSpecialState(model) {
        return model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY;
    }

    static function showSpecialTimerScreen(view, model) {
        if (RugbyTimerOverlay.isSpecialState(model)) {
            view.specialTimerOverlayVisible = true;
        }
    }

    static function closeSpecialTimerScreen(view) {
        if (view.specialTimerOverlayVisible) {
            view.specialTimerOverlayVisible = false;
        }
    }

    static function isSpecialOverlayActive(view, model) {
        return view.specialTimerOverlayVisible && RugbyTimerOverlay.isSpecialState(model);
    }

    static function getOverlayMainCountdownText(model) {
        return RugbyTimerTiming.formatTime(RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownRemaining));
    }

    static function getOverlayCountdownText(model) {
        return RugbyTimerTiming.formatTime(RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownSeconds));
    }

    static function getSpecialOverlayHint(model) {
        if (model.gameState == STATE_CONVERSION) {
            return RugbyTimerOverlay.loadString(Rez.Strings.Overlay_Hint_Conversion);
        } else if (model.gameState == STATE_PENALTY) {
            return RugbyTimerOverlay.loadString(Rez.Strings.Overlay_Hint_Penalty);
        }
        return RugbyTimerOverlay.loadString(Rez.Strings.Overlay_Hint_SelectBack);
    }

    static function getSpecialStateLabel(model) {
        if (model.gameState == STATE_CONVERSION) {
            return RugbyTimerOverlay.loadString(Rez.Strings.State_Conversion);
        } else if (model.gameState == STATE_PENALTY) {
            return RugbyTimerOverlay.loadString(Rez.Strings.State_PenaltyKick);
        }
        return "";
    }

    static function loadString(resourceId) {
        if (resourceId instanceof Lang.String) {
            return resourceId;
        }
        var value = WatchUi.loadResource(resourceId);
        if (value instanceof Lang.String) {
            return value;
        }
        return "";
    }

    static function getSpecialStateColor(model) {
        if (model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY) {
            return Graphics.COLOR_RED;
        }
        return Graphics.COLOR_WHITE;
    }

    static function displaySpecialOverlayMessage(view, text) {
        view.specialOverlayMessage = text;
        view.specialOverlayMessageExpiry = System.getTimer() + 2000;
        WatchUi.requestUpdate();
    }
}
