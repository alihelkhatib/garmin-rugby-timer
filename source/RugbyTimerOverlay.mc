using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.WatchUi;
using Rez.Strings;

/**
 * Special overlay renderer for conversion and penalty states.
 *
 * Purpose: draw the dedicated overlay screen and prompts while keeping the
 * main renderer focused on the normal match screen layout.
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
        var showBreakOverlay = RugbyTimerViewSupport.isHalftimeBreakActive(model);
        if ((!view.specialTimerOverlayVisible || !RugbyTimerOverlay.isSpecialState(model)) && !showBreakOverlay) {
            return;
        }
        try {
            RugbyTimerOverlay.renderSpecialOverlayBody(view, model, dc, width, height);
        } catch (ex) {
            System.println("Error rendering special overlay");
            RugbyTimerOverlay.renderSpecialOverlayFallback(view, model, dc, width, height);
        }
    }

    static function renderSpecialOverlayBody(view, model, dc, width, height) {
        var renderNow = System.getTimer();
        var label = RugbyTimerOverlay.getSpecialStateLabel(model);
        var countdown = RugbyTimerTiming.formatTime(
            RugbyTimerTiming.getDisplayCountdownSeconds(RugbyTimerViewSupport.getSpecialCountdownSeconds(model, renderNow))
        );
        var countdownMain = RugbyTimerOverlay.getOverlayHeaderTime(model, renderNow);
        var specialTimerY = RugbyTimerOverlay.getSpecialTimerY(model, height);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.08, Graphics.FONT_NUMBER_MEDIUM, countdownMain, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(RugbyTimerOverlay.getSpecialStateColor(model), Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.32, Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, specialTimerY, Graphics.FONT_NUMBER_HOT, countdown, Graphics.TEXT_JUSTIFY_CENTER);
        if (RugbyTimerViewSupport.isHalftimeBreakActive(model)) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.81, Graphics.FONT_XTINY, RugbyTimerOverlay.loadString(Rez.Strings.Hint_Halftime_Adjust), Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, height * 0.86, Graphics.FONT_XTINY, RugbyTimerOverlay.loadString(Rez.Strings.Hint_Select_Half2), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            var hint = RugbyTimerOverlay.getSpecialOverlayHint(model);
            if (hint != null && hint.length() > 0) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 2, height * 0.84, Graphics.FONT_XTINY, hint, Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
        if (view.specialOverlayMessage != null && renderNow < view.specialOverlayMessageExpiry) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.65, Graphics.FONT_MEDIUM, view.specialOverlayMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    static function renderSpecialOverlayFallback(view, model, dc, width, height) {
        var renderNow = System.getTimer();
        var label = RugbyTimerOverlay.getSpecialStateLabel(model);
        var countdown = RugbyTimerTiming.formatTime(
            RugbyTimerTiming.getDisplayCountdownSeconds(RugbyTimerViewSupport.getSpecialCountdownSeconds(model, renderNow))
        );
        var specialTimerY = RugbyTimerOverlay.getSpecialTimerY(model, height) - (height * 0.07);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.08, Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, specialTimerY, Graphics.FONT_NUMBER_HOT, countdown, Graphics.TEXT_JUSTIFY_CENTER);
        var hint = RugbyTimerOverlay.getSpecialOverlayHint(model);
        if (hint != null && hint.length() > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.84, Graphics.FONT_XTINY, hint, Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (view.specialOverlayMessage != null && renderNow < view.specialOverlayMessageExpiry) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.65, Graphics.FONT_MEDIUM, view.specialOverlayMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    static function getSpecialTimerY(model, height) {
        if (RugbyTimerViewSupport.isHalftimeBreakActive(model)) {
            return height * 0.50;
        }
        if (model.gameState == STATE_CONVERSION) {
            return height * 0.47;
        }
        return height * 0.55;
    }

    static function getOverlayHeaderTime(model, renderNow) {
        if (RugbyTimerViewSupport.isHalftimeBreakActive(model)) {
            return RugbyTimerTiming.formatTime(
                RugbyTimerViewSupport.getElapsedSeconds(model, renderNow)
            );
        }
        return RugbyTimerTiming.formatTime(
            RugbyTimerTiming.getDisplayCountdownSeconds(RugbyTimerViewSupport.getMainCountdownSeconds(model, renderNow))
        );
    }

    /**
     * Checks if the current game state is a special state.
     * @param model The game model
     * @return true if it is a special state, false otherwise
     */
    static function isSpecialState(model) {
        return model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY;
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
            view.specialOverlayMessage = null;
            view.specialOverlayMessageExpiry = 0;
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
            return RugbyTimerOverlay.loadString(Rez.Strings.Overlay_Hint_Conversion);
        } else if (model.gameState == STATE_PENALTY) {
            return RugbyTimerOverlay.loadString(Rez.Strings.Overlay_Hint_Penalty);
        }
        return RugbyTimerOverlay.loadString(Rez.Strings.Overlay_Hint_SelectBack);
    }



    /**
     * Returns the label for the special state.
     * @param model The game model
     * @return The label for the special state
     */
    static function getSpecialStateLabel(model) {
        if (RugbyTimerViewSupport.isHalftimeBreakActive(model)) {
            return RugbyTimerOverlay.loadString(Rez.Strings.State_HalfTime);
        } else if (model.gameState == STATE_CONVERSION) {
            return RugbyTimerOverlay.loadString(Rez.Strings.State_Conversion);
        } else if (model.gameState == STATE_PENALTY) {
            return RugbyTimerOverlay.loadString(Rez.Strings.State_PenaltyKick);
        }
        return "";
    }

    /**
     * Loads a string resource explicitly so overlay prompts never render as numeric ids.
     */
    static function loadString(resourceId) {
        if (resourceId instanceof Lang.String) {
            return resourceId;
        }
        var value = WatchUi.loadResource(resourceId);
        if (value instanceof Lang.String) {
            return value;
        }
        if (resourceId == Rez.Strings.State_Conversion) { return "CONVERSION"; }
        if (resourceId == Rez.Strings.State_PenaltyKick) { return "PENALTY KICK"; }
        if (resourceId == Rez.Strings.State_HalfTime) { return "HALF TIME"; }
        if (resourceId == Rez.Strings.Hint_Halftime_Adjust) { return "UP/MENU: +1   DOWN: -1"; }
        if (resourceId == Rez.Strings.Hint_Select_Half2) { return "SELECT: Half 2"; }
        if (resourceId == Rez.Strings.Overlay_Hint_Conversion) { return "UP: +2   DOWN: MISS"; }
        if (resourceId == Rez.Strings.Overlay_Hint_Penalty) { return "UP/DOWN: Hide"; }
        if (resourceId == Rez.Strings.Overlay_Hint_SelectBack) { return "SELECT: Back"; }
        return "";
    }

    /**
     * Returns the color for the special state.
     * @param model The game model
     * @return The color for the special state
     */
    static function getSpecialStateColor(model) {
        if (RugbyTimerViewSupport.isHalftimeBreakActive(model)) {
            return Graphics.COLOR_WHITE;
        }
        if (model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY) {
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
        WatchUi.requestUpdate();
    }
}
