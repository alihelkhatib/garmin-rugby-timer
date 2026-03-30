using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
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
        try {
            RugbyTimerOverlay.renderSpecialOverlayBody(view, model, dc, width, height);
        } catch (ex) {
            System.println("Error rendering special overlay");
            RugbyTimerOverlay.renderSpecialOverlayFallback(view, model, dc, width, height);
        }
    }

    static function renderSpecialOverlayBody(view, model, dc, width, height) {
        var label = RugbyTimerOverlay.getSpecialStateLabel(model);
        var countdown = RugbyTimerTiming.formatTime(RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownSeconds));
        var countdownMain = RugbyTimerTiming.formatTime(RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownRemaining));
        var specialTimerY = RugbyTimerOverlay.getSpecialTimerY(model, height);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.08, Graphics.FONT_NUMBER_MEDIUM, countdownMain, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(RugbyTimerOverlay.getSpecialStateColor(model), Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.32, Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, specialTimerY, Graphics.FONT_NUMBER_HOT, countdown, Graphics.TEXT_JUSTIFY_CENTER);
        if (model.gameState == STATE_CONVERSION) {
            try {
                RugbyTimerOverlay.renderConversionButtonPrompts(dc, width, height);
            } catch (ex) {
                System.println("Error rendering conversion prompts");
                RugbyTimerOverlay.renderFallbackConversionButtonPrompts(dc, width, height);
            }
        }
        var hint = RugbyTimerOverlay.getSpecialOverlayHint(model);
        if (hint != null && hint.length() > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.80, Graphics.FONT_XTINY, hint, Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (view.specialOverlayMessage != null && System.getTimer() < view.specialOverlayMessageExpiry) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.65, Graphics.FONT_MEDIUM, view.specialOverlayMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    static function renderSpecialOverlayFallback(view, model, dc, width, height) {
        var label = RugbyTimerOverlay.getSpecialStateLabel(model);
        var countdown = RugbyTimerTiming.formatTime(RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownSeconds));
        var specialTimerY = RugbyTimerOverlay.getSpecialTimerY(model, height) - (height * 0.07);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.08, Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, specialTimerY, Graphics.FONT_NUMBER_HOT, countdown, Graphics.TEXT_JUSTIFY_CENTER);
        if (model.gameState == STATE_CONVERSION) {
            RugbyTimerOverlay.renderFallbackConversionButtonPrompts(dc, width, height);
        }
        if (view.specialOverlayMessage != null && System.getTimer() < view.specialOverlayMessageExpiry) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.72, Graphics.FONT_TINY, view.specialOverlayMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }
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
            return "";
        } else if (model.gameState == STATE_PENALTY) {
            return RugbyTimerOverlay.loadString(Rez.Strings.Overlay_Hint_Penalty);
        }
        return RugbyTimerOverlay.loadString(Rez.Strings.Overlay_Hint_SelectBack);
    }

    /**
     * Draws short conversion prompts beside the left-side hardware buttons while keeping
     * them inside the visible display area on different round Garmin screens.
     */
    static function renderConversionButtonPrompts(dc, width, height) {
        var font = RugbyTimerOverlay.choosePromptFont(width);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        RugbyTimerOverlay.drawPromptBlock(
            dc,
            width,
            height,
            height * 0.43,
            font,
            RugbyTimerOverlay.loadString(Rez.Strings.Overlay_ConversionMade_Action),
            RugbyTimerOverlay.loadString(Rez.Strings.Overlay_ConversionMade_Result)
        );
        RugbyTimerOverlay.drawPromptBlock(
            dc,
            width,
            height,
            height * 0.72,
            font,
            RugbyTimerOverlay.loadString(Rez.Strings.Overlay_ConversionMiss_Action),
            RugbyTimerOverlay.loadString(Rez.Strings.Overlay_ConversionMiss_Result)
        );
    }

    static function choosePromptFont(width) {
        if (width <= 240) {
            return Graphics.FONT_SYSTEM_TINY;
        }
        return Graphics.FONT_XTINY;
    }

    static function renderFallbackConversionButtonPrompts(dc, width, height) {
        var font = RugbyTimerOverlay.choosePromptFont(width);
        dc.drawText(width * 0.18, height * 0.43, font, RugbyTimerOverlay.loadString(Rez.Strings.Overlay_ConversionMade_Result), Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(width * 0.18, height * 0.72, font, RugbyTimerOverlay.loadString(Rez.Strings.Overlay_ConversionMiss_Result), Graphics.TEXT_JUSTIFY_RIGHT);
    }

    /**
     * Draw a compact one-line prompt with an X offset derived from the actual visible
     * bezel edge at the requested Y position so text does not clip on round screens.
     */
    static function drawPromptBlock(dc, width, height, centerY, font, lineOne, lineTwo) {
        var promptX = RugbyTimerOverlay.getPromptAnchorX(width, height, centerY);
        var displayText = lineTwo;
        if (displayText == null || displayText.length() == 0) {
            displayText = lineOne;
        }
        dc.drawText(promptX, centerY, font, displayText, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    static function getPromptAnchorX(width, height, anchorY) {
        var sidePadding = width * 0.06;
        if (sidePadding < 12) { sidePadding = 12; }
        var minimumAnchor = width * 0.18;
        var computedAnchor = RugbyTimerOverlay.getVisibleLeftInset(width, height, anchorY) + sidePadding;
        if (computedAnchor < minimumAnchor) {
            computedAnchor = minimumAnchor;
        }
        return computedAnchor;
    }

    static function getSpecialTimerY(model, height) {
        if (model.gameState == STATE_CONVERSION) {
            return height * 0.47;
        }
        return height * 0.55;
    }

    /**
     * For round screens the visible left edge moves inward near the top and bottom.
     * Model that edge as an ellipse so prompt blocks can be placed just inside it.
     */
    static function getVisibleLeftInset(width, height, y) {
        if (width != height) {
            return 0;
        }
        var radius = width / 2.0f;
        var centerY = height / 2.0f;
        var dy = y - centerY;
        var normalizedSquared = (dy * dy) / (radius * radius);
        if (normalizedSquared >= 1.0f) {
            return 0;
        }
        return radius - (radius * Math.sqrt(1.0f - normalizedSquared));
    }

    /**
     * Returns the label for the special state.
     * @param model The game model
     * @return The label for the special state
     */
    static function getSpecialStateLabel(model) {
        if (model.gameState == STATE_CONVERSION) {
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
        return "";
    }

    /**
     * Returns the color for the special state.
     * @param model The game model
     * @return The color for the special state
     */
    static function getSpecialStateColor(model) {
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
    }
}
