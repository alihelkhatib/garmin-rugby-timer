using Toybox.Graphics;
using Toybox.Lang;

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
    static function chooseFonts(width as Number) as Dictionary {
        // Use compact fonts for smaller screens and a slightly larger tries font on wide displays.
        var scoreFont as FontResource;
        var triesFont as FontResource;
        var halfFont as FontResource;
        var timerFont as FontResource;
        var countdownFont as FontResource;
        var stateFont as FontResource;
        var hintFont as FontResource;
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
        } as Dictionary;
    }

    /**
     * Compute the anchor positions for the scoreboard, half indicator, main game timer, card stack,
     * and the state/hint section so each renders consistently across devices.
     * @param height The height of the screen
     * @return A dictionary of layout values
     */
    static function calculateLayout(height as Number) as Dictionary {
        // Compute the anchor positions for the scoreboard, half indicator, main game timer, card stack,
        // and the state/hint section so each renders consistently across devices.
        var scoreY as Float = height * 0.10;
        var halfY as Float = height * 0.18;
        var gameTimerY as Float = halfY * 0.5;
        var triesY as Float = halfY + height * 0.06;
        var cardsY as Float = height * 0.37;
        var stateBaseY as Float = height * 0.82;
        var hintBaseY as Float = height * 0.92;
        return {
            :scoreY => scoreY,
            :halfY => halfY,
            :gameTimerY => gameTimerY,
            :triesY => triesY,
            :cardsY => cardsY,
            :stateBaseY => stateBaseY,
            :hintBaseY => hintBaseY
        } as Dictionary;
    }

    /**
     * Renders the scores of both teams.
     * @param dc The device context
     * @param model The game model
     * @param width The width of the screen
     * @param scoreFont The font to use for the scores
     * @param scoreY The Y position of the scores
     */
    static function renderScores(dc as Graphics.Dc, model as RugbyGameModel, width as Number, scoreFont as FontResource, scoreY as Number) as Void {
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
    static function renderGameTimer(dc as Graphics.Dc, model as RugbyGameModel, width as Number, timerFont as FontResource, gameTimerY as Number) as Void {
        var gameStr = RugbyTimerTiming.formatTime(model.gameTime) as String;
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
    static function renderHalfAndTries(dc as Graphics.Dc, model as RugbyGameModel, width as Number, halfFont as FontResource, triesFont as FontResource, halfY as Number, triesY as Number) as Void {
        var halfStr = Rez.Strings.HalfPrefix + model.halfNumber.toString() as String;
        dc.drawText(width / 2, halfY, halfFont, halfStr, Graphics.TEXT_JUSTIFY_CENTER);
        var triesText = model.homeTries.toString() + Rez.Strings.TrySeparator + model.awayTries.toString() + "T" as String;
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
    static function renderLockIndicator(dc as Graphics.Dc, view as RugbyTimerView, width as Number, halfFont as FontResource, scoreY as Number) as Void {
        dc.drawText(width - (width * 0.1).toLong(), scoreY, halfFont, Rez.Strings.LockIndicator, Graphics.TEXT_JUSTIFY_CENTER);
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
    static function renderCardTimers(dc as Graphics.Dc, model as RugbyGameModel, width as Number, cardsY as Number, height as Number) as Dictionary {
        // Only render the first two yellows per team plus any active red timers so the primary layout
        // stays tidy while extra timers still count in the background.
        var visibleYellowHome as Number = model.yellowHomeTimes.size() > 2 ? 2 : model.yellowHomeTimes.size();
        var visibleYellowAway as Number = model.yellowAwayTimes.size() > 2 ? 2 : model.yellowAwayTimes.size();
        var homeCardRows as Number = visibleYellowHome + ((model.redHome > 0 || model.redHomePermanent) ? 1 : 0);
        var awayCardRows as Number = visibleYellowAway + ((model.redAway > 0 || model.redAwayPermanent) ? 1 : 0);
        var maxCardRows as Number = (homeCardRows > awayCardRows) ? homeCardRows : awayCardRows;
        var lineStep as Float = height * 0.1;
        if (maxCardRows > 0) {
            var homeLine as Number = 0;
            var awayLine as Number = 0;
            var cardFont as FontResource = Graphics.FONT_MEDIUM;
            var homeYellowDisplayed as Number = 0;
            for (var i as Number = 0; i < model.yellowHomeTimes.size() && homeYellowDisplayed < 2; i = i + 1) {
                var entry = model.yellowHomeTimes[i] as Lang.Dictionary or Null;
                if (entry == null) {
                    homeLine += 1;
                } else {
                    var y = entry["remaining"] as Float;
                    var label = entry["label"] as String or Null;
                    if (label == null) {
                        label = "Y" + (homeYellowDisplayed + 1).toString();
                    }
                    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(width / 4, cardsY + homeLine * lineStep, cardFont, label + ":" + model.formatShortTime(y), Graphics.TEXT_JUSTIFY_CENTER);
                    homeYellowDisplayed += 1;
                }
                homeLine += 1;
            }
            var awayYellowDisplayed as Number = 0;
            for (var i as Number = 0; i < model.yellowAwayTimes.size() && awayYellowDisplayed < 2; i = i + 1) {
                var entry = model.yellowAwayTimes[i] as Lang.Dictionary or Null;
                if (entry == null) {
                    awayLine += 1;
                } else {
                    var y = entry["remaining"] as Float;
                    var label = entry["label"] as String or Null;
                    if (label == null) {
                        label = "Y" + (awayYellowDisplayed + 1).toString();
                    }
                    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(3 * width / 4, cardsY + awayLine * lineStep, cardFont, label + ":" + model.formatShortTime(y), Graphics.TEXT_JUSTIFY_CENTER);
                    awayYellowDisplayed += 1;
                }
                awayLine += 1;
            }
            if (model.redHome > 0 || model.redHomePermanent) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 4, cardsY + homeLine * lineStep, cardFont, model.redHomePermanent ? "R:PERM" : "R:" + model.formatShortTime(model.redHome), Graphics.TEXT_JUSTIFY_CENTER);
                homeLine += 1;
            }
            if (model.redAway > 0 || model.redAwayPermanent) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(3 * width / 4, cardsY + awayLine * lineStep, cardFont, model.redAwayPermanent ? "R:PERM" : "R:" + model.formatShortTime(model.redAway), Graphics.TEXT_JUSTIFY_CENTER);
                awayLine += 1;
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        return {:rows => maxCardRows, :lineStep => lineStep, :cardsY => cardsY} as Dictionary;
    }

    /**
     * Calculates the position of the countdown timer.
     * @param layout The layout dictionary
     * @param cardInfo The card information dictionary
     * @param height The height of the screen
     * @return The Y position of the countdown timer
     */
    static function calculateCountdownPosition(layout as Dictionary, cardInfo as Dictionary, height as Number) as Number {
        // Place the countdown timer below the card stack while enforcing a ceiling for the state block.
        // countdownCandidate is the naive position just below the cards, and countdownLimit ensures the
        // state/hint text has room above the bottom edge. countdownMin keeps the countdown above the
        // half/tries indicators so it never overlaps the score area.
        var cardStackBottom as Float = cardInfo[:cardsY] + (cardInfo[:rows] * cardInfo[:lineStep]);
        var countdownCandidate as Float = cardStackBottom + height * 0.04;
        var countdownLimit as Float = (layout[:stateBaseY] as Number) - height * 0.18;
        var countdownMin as Float = (layout[:triesY] as Number) + height * 0.05;
        var candidateTimerY as Float = (countdownCandidate < countdownLimit) ? countdownCandidate : countdownLimit;
        var countdownY as Number = (candidateTimerY > countdownMin) ? candidateTimerY : countdownMin;
        return countdownY;
    }

    /**
     * Calculates the position of the state text.
     * @param countdownY The Y position of the countdown timer
     * @param layout The layout dictionary
     * @param height The height of the screen
     * @return The Y position of the state text
     */
    static function calculateStateY(countdownY as Number, layout as Dictionary, height as Number) as Number {
        // Anchor the state text slightly below the countdown timer, unless the reserved base position is lower.
        return (countdownY + height * 0.09 > (layout[:stateBaseY] as Number)) ? (countdownY + height * 0.09).toNumber() : (layout[:stateBaseY] as Number);
    }

    /**
     * Calculates the position of the hint text.
     * @param stateY The Y position of the state text
     * @param hintBaseY The base Y position of the hint text
     * @param height The height of the screen
     * @return The Y position of the hint text
     */
    static function calculateHintY(stateY as Number, hintBaseY as Number, height as Number) as Number {
        // Keep the hint block beneath the state text or at the bottom hint base, whichever sits lower.
        return (stateY + height * 0.08 > hintBaseY) ? (stateY + height * 0.08).toNumber() : hintBaseY;
    }

    /**
     * Renders the countdown timer.
     * @param dc The device context
     * @param model The game model
     * @param width The width of the screen
     * @param countdownFont The font to use for the countdown timer
     * @param countdownY The Y position of the countdown timer
     */
    static function renderCountdown(dc as Graphics.Dc, model as RugbyGameModel, width as Number, countdownFont as FontResource, countdownY as Number) as Void {
        // Draw the large, white countdown digits centered so refs can still read the main clock even when the overlay
        // kicks in.
        var countdownStr = RugbyTimerTiming.formatTime(model.countdownRemaining) as String;
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
    static function renderStateText(dc as Graphics.Dc, model as RugbyGameModel, width as Number, stateFont as FontResource, stateY as Number, height as Number) as Void {
        // Each special state adopts a red accent, while the idle/paused text stays white for clarity.
        var stateColor as ColorValue = Graphics.COLOR_WHITE;
        if (model.gameState == STATE_CONVERSION || model.gameState == STATE_KICKOFF || model.gameState == STATE_PENALTY) {
            stateColor = Graphics.COLOR_RED;
        }
        dc.setColor(stateColor, Graphics.COLOR_TRANSPARENT);
        if (model.gameState == STATE_PAUSED) {
            dc.drawText(width / 2, stateY, stateFont, Rez.Strings.State_Paused, Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_CONVERSION) {
            dc.drawText(width / 2, stateY, stateFont, Rez.Strings.State_Conversion, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, model.countdownSeconds.toLong().toString() + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_PENALTY) {
            dc.drawText(width / 2, stateY, stateFont, Rez.Strings.State_PenaltyKick, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, model.countdownSeconds.toLong().toString() + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_KICKOFF) {
            dc.drawText(width / 2, stateY, stateFont, Rez.Strings.State_Kickoff, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, model.countdownSeconds.toLong().toString() + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_HALFTIME) {
            dc.drawText(width / 2, stateY, stateFont, Rez.Strings.State_HalfTime, Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_ENDED) {
            dc.drawText(width / 2, stateY, stateFont, Rez.Strings.State_GameEnded, Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_IDLE) {
            dc.drawText(width / 2, stateY, stateFont, Rez.Strings.State_ReadyToStart, Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

}