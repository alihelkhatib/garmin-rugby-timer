using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;

class RugbyTimerOverlay {
    static function renderSpecialOverlay(view, dc, width, height) {
        if (!view.specialTimerOverlayVisible || !RugbyTimerOverlay.isSpecialState(view)) {
            return;
        }
        var label = RugbyTimerOverlay.getSpecialStateLabel(view);
        var countdown = RugbyTimerTiming.formatTime(view.countdownSeconds);
        var countdownMain = RugbyTimerTiming.formatTime(view.countdownRemaining);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.04, Graphics.FONT_XTINY, "COUNTDOWN", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.12, Graphics.FONT_NUMBER_MEDIUM, countdownMain, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(RugbyTimerOverlay.getSpecialStateColor(view), Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.32, Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.55, Graphics.FONT_NUMBER_HOT, countdown, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.80, Graphics.FONT_XTINY, RugbyTimerOverlay.getSpecialOverlayHint(view), Graphics.TEXT_JUSTIFY_CENTER);
        if (view.specialOverlayMessage != null && System.getTimer() < view.specialOverlayMessageExpiry) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.65, Graphics.FONT_MEDIUM, view.specialOverlayMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    static function isSpecialState(view) {
        return view.gameState == STATE_CONVERSION || view.gameState == STATE_PENALTY || view.gameState == STATE_KICKOFF;
    }

    static function showSpecialTimerScreen(view) {
        if (RugbyTimerOverlay.isSpecialState(view)) {
            view.specialTimerOverlayVisible = true;
            WatchUi.requestUpdate();
        }
    }

    static function closeSpecialTimerScreen(view) {
        if (view.specialTimerOverlayVisible) {
            view.specialTimerOverlayVisible = false;
            WatchUi.requestUpdate();
        }
    }

    static function isSpecialOverlayActive(view) {
        return view.specialTimerOverlayVisible && RugbyTimerOverlay.isSpecialState(view);
    }

    static function getSpecialOverlayHint(view) {
        if (view.gameState == STATE_CONVERSION) {
            return "UP: Success  DOWN: Miss";
        } else if (view.gameState == STATE_PENALTY) {
            return "UP: Success  DOWN: Miss";
        } else if (view.gameState == STATE_KICKOFF) {
            return "UP: Resume  DOWN: Cancel";
        }
        return "SELECT: Back";
    }

    static function getSpecialStateLabel(view) {
        if (view.gameState == STATE_CONVERSION) {
            return "CONVERSION";
        } else if (view.gameState == STATE_PENALTY) {
            return "PENALTY KICK";
        } else if (view.gameState == STATE_KICKOFF) {
            return "KICKOFF";
        }
        return "";
    }

    static function getSpecialStateColor(view) {
        if (view.gameState == STATE_CONVERSION || view.gameState == STATE_KICKOFF || view.gameState == STATE_PENALTY) {
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
