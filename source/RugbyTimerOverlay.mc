using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;
using Rez.Strings;

/**
 * A helper class for rendering the special timer overlay.
 */
class RugbyTimerOverlay {
    /**
     * Renders the special overlay.
     * @param view The main view
     * @param model The game model
     * @param dc The device context
     * @param width The width of the screen
     * @param height The height of the screen
     */
    static function renderSpecialOverlay(view, model, dc, width, height) {
        if (!view.specialTimerOverlayVisible || !RugbyTimerOverlay.isSpecialState(model)) {
            return;
        }
        var label = RugbyTimerOverlay.getSpecialStateLabel(model);
        var countdown = RugbyTimerTiming.formatTime(model.countdownSeconds);
        var countdownMain = RugbyTimerTiming.formatTime(model.countdownRemaining);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.04, Graphics.FONT_XTINY, Rez.Strings.Overlay_Countdown, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.12, Graphics.FONT_NUMBER_MEDIUM, countdownMain, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(RugbyTimerOverlay.getSpecialStateColor(model), Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.32, Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.55, Graphics.FONT_NUMBER_HOT, countdown, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.80, Graphics.FONT_XTINY, RugbyTimerOverlay.getSpecialOverlayHint(model), Graphics.TEXT_JUSTIFY_CENTER);
        if (view.specialOverlayMessage != null && System.getTimer() < view.specialOverlayMessageExpiry) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.65, Graphics.FONT_MEDIUM, view.specialOverlayMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    /**
     * Checks if the current game state is a special state.
     * @param model The game model
     * @return true if it is a special state, false otherwise
     */
    static function isSpecialState(model) {
        return model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF;
    }

    /**
     * Shows the special timer screen.
     * @param view The main view
     * @param model The game model
     */
    static function showSpecialTimerScreen(view, model) {
        if (RugbyTimerOverlay.isSpecialState(model)) {
            view.specialTimerOverlayVisible = true;
        }
    }

    /**
     * Closes the special timer screen.
     * @param view The main view
     */
    static function closeSpecialTimerScreen(view) {
        if (view.specialTimerOverlayVisible) {
            view.specialTimerOverlayVisible = false;
        }
    }

    /**
     * Checks if the special overlay is active.
     * @param view The main view
     * @param model The game model
     * @return true if the special overlay is active, false otherwise
     */
    static function isSpecialOverlayActive(view, model) {
        return view.specialTimerOverlayVisible && RugbyTimerOverlay.isSpecialState(model);
    }

    /**
     * Returns the hint text for the special overlay.
     * @param model The game model
     * @return The hint text
     */
    static function getSpecialOverlayHint(model) {
        if (model.gameState == STATE_CONVERSION) {
            return Rez.Strings.Overlay_Hint_Conversion;
        } else if (model.gameState == STATE_PENALTY) {
            return Rez.Strings.Overlay_Hint_Conversion; // Same hint for penalty kick
        } else if (model.gameState == STATE_KICKOFF) {
            return Rez.Strings.Overlay_Hint_Kickoff;
        }
        return Rez.Strings.Overlay_Hint_SelectBack;
    }

    /**
     * Returns the label for the special state.
     * @param model The game model
     * @return The label for the special state
     */
    static function getSpecialStateLabel(model) {
        if (model.gameState == STATE_CONVERSION) {
            return Rez.Strings.State_Conversion;
        } else if (model.gameState == STATE_PENALTY) {
            return Rez.Strings.State_PenaltyKick;
        } else if (model.gameState == STATE_KICKOFF) {
            return Rez.Strings.State_Kickoff;
        }
        return "";
    }

    /**
     * Returns the color for the special state.
     * @param model The game model
     * @return The color for the special state
     */
    static function getSpecialStateColor(model) {
        if (model.gameState == STATE_CONVERSION || model.gameState == STATE_KICKOFF || model.gameState == STATE_PENALTY) {
            return Graphics.COLOR_RED;
        }
        return Graphics.COLOR_WHITE;
    }

    /**
     * Displays a message on the special overlay.
     * @param view The main view
     * @param text The text to display
     */
    static function displaySpecialOverlayMessage(view, text) {
        view.specialOverlayMessage = text;
        view.specialOverlayMessageExpiry = System.getTimer() + 2000;
    }
}