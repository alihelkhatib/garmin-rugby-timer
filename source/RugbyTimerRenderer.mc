using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

/**
 * A helper class for rendering the UI elements.
 * This class contains static methods for drawing the various components of the UI.
 */
class RugbyTimerRenderer {
    /**
     * Central rendering helper that keeps layout math and font selection in one place so
     * the view can focus on state updates and overlays.
     * @param width The width of the screen
     * @return A dictionary of fonts
     */
    static function chooseFonts(width) {
        // Use compact fonts for smaller screens and a slightly larger tries font on wide displays.
        var scoreFont;
        var triesFont;
        var halfFont;
        var timerFont;
        var countdownFont;
        var stateFont;
        var hintFont;
        if (width <= 240) {
            scoreFont = Graphics.FONT_NUMBER_MEDIUM;
            triesFont = Graphics.FONT_XTINY;
            halfFont = Graphics.FONT_XTINY;
            timerFont = Graphics.FONT_SYSTEM_TINY;
            countdownFont = Graphics.FONT_NUMBER_HOT;
            stateFont = Graphics.FONT_SMALL;
            hintFont = Graphics.FONT_XTINY;
        } else if (width <= 260) {
            scoreFont = Graphics.FONT_NUMBER_MEDIUM;
            triesFont = Graphics.FONT_XTINY;
            halfFont = Graphics.FONT_XTINY;
            timerFont = Graphics.FONT_SYSTEM_TINY;
            countdownFont = Graphics.FONT_NUMBER_HOT;
            stateFont = Graphics.FONT_SMALL;
            hintFont = Graphics.FONT_XTINY;
        } else {
            scoreFont = Graphics.FONT_NUMBER_MEDIUM;
            triesFont = Graphics.FONT_SMALL;
            halfFont = Graphics.FONT_XTINY;
            timerFont = Graphics.FONT_SYSTEM_TINY;
            countdownFont = Graphics.FONT_NUMBER_HOT;
            stateFont = Graphics.FONT_SMALL;
            hintFont = Graphics.FONT_XTINY;
        }
        return {
            :scoreFont => scoreFont,
            :triesFont => triesFont,
            :halfFont => halfFont,
            :timerFont => timerFont,
            :countdownFont => countdownFont,
            :stateFont => stateFont,
            :hintFont => hintFont
        };
    }

    /**
     * Compute the anchor positions for the scoreboard, half indicator, main game timer, card stack,
     * and the state/hint section so each renders consistently across devices.
     * @param height The height of the screen
     * @return A dictionary of layout values
     */
    static function calculateLayout(height) {
        // Compute the anchor positions for the scoreboard, half indicator, main game timer, card stack,
        // and the state/hint section so each renders consistently across devices.
        var scoreY = height * 0.10;
        var halfY = height * 0.18;
        var gameTimerY = halfY * 0.5;
        var triesY = halfY + height * 0.06;
        var cardsY = height * 0.37;
        var stateBaseY = height * 0.82;
        var hintBaseY = height * 0.92;
        return {
            :scoreY => scoreY,
            :halfY => halfY,
            :gameTimerY => gameTimerY,
            :triesY => triesY,
            :cardsY => cardsY,
            :stateBaseY => stateBaseY,
            :hintBaseY => hintBaseY
        };
    }

    /**
     * Renders the scores of both teams.
     * @param dc The device context
     * @param model The game model
     * @param width The width of the screen
     * @param scoreFont The font to use for the scores
     * @param scoreY The Y position of the scores
     */
    static function renderScores(dc, model, width, scoreFont, scoreY) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 4, scoreY, scoreFont, model.homeScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(3 * width / 4, scoreY, scoreFont, model.awayScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    /**
     * Renders the main game timer.
     * @param dc The device context
     * @param model The game model
     * @param width The width of the screen
     * @param timerFont The font to use for the timer
     * @param gameTimerY The Y position of the timer
     */
    static function renderGameTimer(dc, model, width, timerFont, gameTimerY) {
        var gameStr = RugbyTimerTiming.formatTime(model.gameTime);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, gameTimerY, timerFont, gameStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    /**
     * Renders the half number and the number of tries for each team.
     * @param dc The device context
     * @param model The game model
     * @param width The width of the screen
     * @param halfFont The font to use for the half number
     * @param triesFont The font to use for the tries
     * @param halfY The Y position of the half number
     * @param triesY The Y position of the tries
     */
    static function renderHalfAndTries(dc, model, width, halfFont, triesFont, halfY, triesY) {
        var halfStr = "Half " + model.halfNumber.toString();
        dc.drawText(width / 2, halfY, halfFont, halfStr, Graphics.TEXT_JUSTIFY_CENTER);
        var triesText = model.homeTries.toString() + "T / " + model.awayTries.toString() + "T";
        dc.drawText(width / 2, triesY, triesFont, triesText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    /**
     * Renders the lock indicator.
     * @param dc The device context
     * @param view The view
     * @param width The width of the screen
     * @param halfFont The font to use for the lock indicator
     * @param scoreY The Y position of the lock indicator
     */
    static function renderLockIndicator(dc, view, width, halfFont, scoreY) {
        dc.drawText(width - (width * 0.1).toLong(), scoreY, halfFont, "L", Graphics.TEXT_JUSTIFY_CENTER);
    }

    /**
     * Renders the card timers.
     * @param dc The device context
     * @param model The game model
     * @param width The width of the screen
     * @param cardsY The Y position of the card timers
     * @param height The height of the screen
     * @return A dictionary containing information about the rendered cards
     */
    static function renderCardTimers(dc, model, width, cardsY, height) {
        // Only render the first two yellows per team plus any active red timers so the primary layout
        // stays tidy while extra timers still count in the background.
        if (model.yellowHomeTimes == null) { model.yellowHomeTimes = []; }
        if (model.yellowAwayTimes == null) { model.yellowAwayTimes = []; }
        var visibleYellowHome = model.yellowHomeTimes.size() > 2 ? 2 : model.yellowHomeTimes.size();
        var visibleYellowAway = model.yellowAwayTimes.size() > 2 ? 2 : model.yellowAwayTimes.size();
        var redHomeActive = (model.redHome != null && model.redHome > 0) || model.redHomePermanent;
        var redAwayActive = (model.redAway != null && model.redAway > 0) || model.redAwayPermanent;
        var homeCardRows = visibleYellowHome + (redHomeActive ? 1 : 0);
        var awayCardRows = visibleYellowAway + (redAwayActive ? 1 : 0);
        var maxCardRows = (homeCardRows > awayCardRows) ? homeCardRows : awayCardRows;
        var lineStep = height * 0.1;
        if (maxCardRows > 0) {
            var homeLine = 0;
            var awayLine = 0;
            var cardFont = Graphics.FONT_MEDIUM;
            var cardFontRed = Graphics.FONT_SMALL;
            var homeYellowDisplayed = 0;
            for (var i = 0; i < model.yellowHomeTimes.size() && homeYellowDisplayed < 2; i = i + 1) {
                var entry = model.yellowHomeTimes[i] as Lang.Dictionary;
                if (entry == null) {
                    homeLine += 1;
                    continue;
                }
                var y = entry["remaining"];
                if (y == null && entry["startTime"] != null && entry["duration"] != null) {
                    y = entry["duration"] - ((System.getTimer() - entry["startTime"]) / 1000.0f);
                }
                if (!(y instanceof Lang.Number)) { y = 0; }
                if (y < 0) { y = 0; }
                var label = entry["label"];
                if (label == null) {
                    label = "Y" + (homeYellowDisplayed + 1).toString();
                }
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 4, cardsY + homeLine * lineStep, cardFont, label + ":" + model.formatShortTime(y), Graphics.TEXT_JUSTIFY_CENTER);
                homeYellowDisplayed += 1;
                homeLine += 1;
            }
            var awayYellowDisplayed = 0;
            for (var i = 0; i < model.yellowAwayTimes.size() && awayYellowDisplayed < 2; i = i + 1) {
                var entry = model.yellowAwayTimes[i] as Lang.Dictionary;
                if (entry == null) {
                    awayLine += 1;
                    continue;
                }
                var y2 = entry["remaining"];
                if (y2 == null && entry["startTime"] != null && entry["duration"] != null) {
                    y2 = entry["duration"] - ((System.getTimer() - entry["startTime"]) / 1000.0f);
                }
                if (!(y2 instanceof Lang.Number)) { y2 = 0; }
                if (y2 < 0) { y2 = 0; }
                var label2 = entry["label"];
                if (label2 == null) {
                    label2 = "Y" + (awayYellowDisplayed + 1).toString();
                }
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(3 * width / 4, cardsY + awayLine * lineStep, cardFont, label2 + ":" + model.formatShortTime(y2), Graphics.TEXT_JUSTIFY_CENTER);
                awayYellowDisplayed += 1;
                awayLine += 1;
            }
            if (redHomeActive) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                var redText;
                if (model.redHomePermanent) {
                    redText = "R:PERM";
                } else if (model.redHome != null) {
                    var redRemaining = 1200 - ((System.getTimer() - model.redHome) / 1000.0f);
                    if (redRemaining < 0) { redRemaining = 0; }
                    redText = "R:" + model.formatShortTime(redRemaining);
                } else {
                    redText = "R:--";
                }
                dc.drawText(width / 4, cardsY + homeLine * lineStep, cardFontRed, redText, Graphics.TEXT_JUSTIFY_CENTER);
                homeLine += 1;
            }
            if (redAwayActive) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                var redAwayText;
                if (model.redAwayPermanent) {
                    redAwayText = "R:PERM";
                } else if (model.redAway != null) {
                    var redAwayRemaining = 1200 - ((System.getTimer() - model.redAway) / 1000.0f);
                    if (redAwayRemaining < 0) { redAwayRemaining = 0; }
                    redAwayText = "R:" + model.formatShortTime(redAwayRemaining);
                } else {
                    redAwayText = "R:--";
                }
                dc.drawText(3 * width / 4, cardsY + awayLine * lineStep, cardFontRed, redAwayText, Graphics.TEXT_JUSTIFY_CENTER);
                awayLine += 1;
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        return {:rows => maxCardRows, :lineStep => lineStep, :cardsY => cardsY};
    }

    /**
     * Calculates the position of the countdown timer.
     * @param layout The layout dictionary
     * @param cardInfo The card information dictionary
     * @param height The height of the screen
     * @return The Y position of the countdown timer
     */
    static function calculateCountdownPosition(layout, cardInfo, height) {
        // Place the countdown timer below the card stack while enforcing a ceiling for the state block.
        // countdownCandidate is the naive position just below the cards, and countdownLimit ensures the
        // state/hint text has room above the bottom edge. countdownMin keeps the countdown above the
        // half/tries indicators so it never overlaps the score area.
        var cardStackBottom = cardInfo[:cardsY] + (cardInfo[:rows] * cardInfo[:lineStep]);
        var countdownCandidate = cardStackBottom + height * 0.04;
        var countdownLimit = layout[:stateBaseY] - height * 0.18;
        var countdownMin = layout[:triesY] + height * 0.05;
        var candidateTimerY = (countdownCandidate < countdownLimit) ? countdownCandidate : countdownLimit;
        var countdownY = (candidateTimerY > countdownMin) ? candidateTimerY : countdownMin;
        return countdownY;
    }

    /**
     * Calculates the position of the state text.
     * @param countdownY The Y position of the countdown timer
     * @param layout The layout dictionary
     * @param height The height of the screen
     * @return The Y position of the state text
     */
    static function calculateStateY(countdownY, layout, height) {
        // Anchor the state text slightly below the countdown timer, unless the reserved base position is lower.
        return (countdownY + height * 0.09 > layout[:stateBaseY]) ? countdownY + height * 0.09 : layout[:stateBaseY];
    }

    /**
     * Calculates the position of the hint text.
     * @param stateY The Y position of the state text
     * @param hintBaseY The base Y position of the hint text
     * @param height The height of the screen
     * @return The Y position of the hint text
     */
    static function calculateHintY(stateY, hintBaseY, height) {
        // Keep the hint block beneath the state text or at the bottom hint base, whichever sits lower.
        return (stateY + height * 0.08 > hintBaseY) ? stateY + height * 0.08 : hintBaseY;
    }

    /**
     * Renders the countdown timer.
     * @param dc The device context
     * @param model The game model
     * @param width The width of the screen
     * @param countdownFont The font to use for the countdown timer
     * @param countdownY The Y position of the countdown timer
     */
    static function renderCountdown(dc, model, width, countdownFont, countdownY) {
        // Draw the large, white countdown digits centered so refs can still read the main clock even when the overlay
        // kicks in.
        var displaySeconds = model.countdownRemaining + 0.999; // prevent dropping a second early
        if (displaySeconds < 0) { displaySeconds = 0; }
        var countdownStr = RugbyTimerTiming.formatTime(displaySeconds);
        dc.drawText(width / 2, countdownY, countdownFont, countdownStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    /**
     * Renders the state text.
     * @param dc The device context
     * @param model The game model
     * @param width The width of the screen
     * @param stateFont The font to use for the state text
     * @param stateY The Y position of the state text
     * @param height The height of the screen
     */
    static function renderStateText(dc, model, width, stateFont, stateY, height) {
        // Each special state adopts a red accent, while the idle/paused text stays white for clarity.
        var stateColor = Graphics.COLOR_WHITE;
        if (model.gameState == STATE_CONVERSION || model.gameState == STATE_KICKOFF || model.gameState == STATE_PENALTY) {
            stateColor = Graphics.COLOR_RED;
        }
        dc.setColor(stateColor, Graphics.COLOR_TRANSPARENT);
        if (model.gameState == STATE_PAUSED) {
            dc.drawText(width / 2, stateY, stateFont, "PAUSED", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_CONVERSION) {
            dc.drawText(width / 2, stateY, stateFont, "CONVERSION", Graphics.TEXT_JUSTIFY_CENTER);
            var convSeconds = (model.countdownSeconds == null) ? 0 : model.countdownSeconds + 0.999;
            if (convSeconds < 0) { convSeconds = 0; }
            var countdownStr = (convSeconds as Lang.Number).toLong().toString();
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, countdownStr + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_PENALTY) {
            dc.drawText(width / 2, stateY, stateFont, "PENALTY KICK", Graphics.TEXT_JUSTIFY_CENTER);
            var penSeconds = (model.countdownSeconds == null) ? 0 : model.countdownSeconds + 0.999;
            if (penSeconds < 0) { penSeconds = 0; }
            var countdownStr = (penSeconds as Lang.Number).toLong().toString();
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, countdownStr + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_KICKOFF) {
            dc.drawText(width / 2, stateY, stateFont, "KICKOFF", Graphics.TEXT_JUSTIFY_CENTER);
            var koSeconds = (model.countdownSeconds == null) ? 0 : model.countdownSeconds + 0.999;
            if (koSeconds < 0) { koSeconds = 0; }
            var countdownStr = (koSeconds as Lang.Number).toLong().toString();
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, countdownStr + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_HALFTIME) {
            dc.drawText(width / 2, stateY, stateFont, "HALF TIME", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_ENDED) {
            dc.drawText(width / 2, stateY, stateFont, "GAME ENDED", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_IDLE) {
            dc.drawText(width / 2, stateY, stateFont, "Ready to start", Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

}
