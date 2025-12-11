using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;

class RugbyTimerOverlay {
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
        dc.drawText(width / 2, height * 0.04, Graphics.FONT_XTINY, "COUNTDOWN", Graphics.TEXT_JUSTIFY_CENTER);
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

    static function isSpecialState(model) {
        return model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF;
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

    static function getSpecialOverlayHint(model) {
        if (model.gameState == STATE_CONVERSION) {
            return "UP: Success  DOWN: Miss";
        } else if (model.gameState == STATE_PENALTY) {
            return "UP: Success  DOWN: Miss";
        } else if (model.gameState == STATE_KICKOFF) {
            return "UP: Resume  DOWN: Cancel";
        }
        return "SELECT: Back";
    }

    static function getSpecialStateLabel(model) {
        if (model.gameState == STATE_CONVERSION) {
            return "CONVERSION";
        } else if (model.gameState == STATE_PENALTY) {
            return "PENALTY KICK";
        } else if (model.gameState == STATE_KICKOFF) {
            return "KICKOFF";
        }
        return "";
    }

    static function getSpecialStateColor(model) {
        if (model.gameState == STATE_CONVERSION || model.gameState == STATE_KICKOFF || model.gameState == STATE_PENALTY) {
            return Graphics.COLOR_RED;
        }
        return Graphics.COLOR_WHITE;
    }

    static function displaySpecialOverlayMessage(view, text) {
        view.specialOverlayMessage = text;
        view.specialOverlayMessageExpiry = System.getTimer() + 2000;
    }
}
