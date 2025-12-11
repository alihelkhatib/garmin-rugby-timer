using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

class RugbyTimerRenderer {
    // Central rendering helper that keeps layout math and font selection in one place so
    // the view can focus on state updates and overlays.
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

    static function renderScores(dc, view, width, scoreFont, scoreY) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 4, scoreY, scoreFont, view.homeScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(3 * width / 4, scoreY, scoreFont, view.awayScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    static function renderGameTimer(dc, view, width, timerFont, gameTimerY) {
        var gameStr = view.formatTime(view.gameTime);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, gameTimerY, timerFont, gameStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    static function renderHalfAndTries(dc, view, width, halfFont, triesFont, halfY, triesY) {
        var halfStr = "Half " + view.halfNumber.toString();
        dc.drawText(width / 2, halfY, halfFont, halfStr, Graphics.TEXT_JUSTIFY_CENTER);
        var triesText = view.homeTries.toString() + "T / " + view.awayTries.toString() + "T";
        dc.drawText(width / 2, triesY, triesFont, triesText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    static function renderLockIndicator(dc, view, width, halfFont, scoreY) {
        dc.drawText(width - (width * 0.1).toLong(), scoreY, halfFont, "L", Graphics.TEXT_JUSTIFY_CENTER);
    }

    static function renderCardTimers(dc, view, width, cardsY, height) {
        // Only render the first two yellows per team plus any active red timers so the primary layout
        // stays tidy while extra timers still count in the background.
        var visibleYellowHome = view.yellowHomeTimes.size() > 2 ? 2 : view.yellowHomeTimes.size();
        var visibleYellowAway = view.yellowAwayTimes.size() > 2 ? 2 : view.yellowAwayTimes.size();
        var homeCardRows = visibleYellowHome + ((view.redHome > 0 || view.redHomePermanent) ? 1 : 0);
        var awayCardRows = visibleYellowAway + ((view.redAway > 0 || view.redAwayPermanent) ? 1 : 0);
        var maxCardRows = (homeCardRows > awayCardRows) ? homeCardRows : awayCardRows;
        var lineStep = height * 0.1;
        if (maxCardRows > 0) {
            var homeLine = 0;
            var awayLine = 0;
            var cardFont = Graphics.FONT_MEDIUM;
            var homeYellowDisplayed = 0;
            for (var i = 0; i < view.yellowHomeTimes.size() && homeYellowDisplayed < 2; i = i + 1) {
                var entry = view.yellowHomeTimes[i] as Lang.Dictionary;
                if (entry == null) {
                    homeLine += 1;
                } else {
                    var y = entry["remaining"];
                    var label = entry["label"];
                    if (label == null) {
                        label = "Y" + (homeYellowDisplayed + 1).toString();
                    }
                    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(width / 4, cardsY + homeLine * lineStep, cardFont, label + ":" + view.formatShortTime(y), Graphics.TEXT_JUSTIFY_CENTER);
                    homeYellowDisplayed += 1;
                }
                homeLine += 1;
            }
            var awayYellowDisplayed = 0;
            for (var i = 0; i < view.yellowAwayTimes.size() && awayYellowDisplayed < 2; i = i + 1) {
                var entry = view.yellowAwayTimes[i] as Lang.Dictionary;
                if (entry == null) {
                    awayLine += 1;
                } else {
                    var y = entry["remaining"];
                    var label = entry["label"];
                    if (label == null) {
                        label = "Y" + (awayYellowDisplayed + 1).toString();
                    }
                    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(3 * width / 4, cardsY + awayLine * lineStep, cardFont, label + ":" + view.formatShortTime(y), Graphics.TEXT_JUSTIFY_CENTER);
                    awayYellowDisplayed += 1;
                }
                awayLine += 1;
            }
            if (view.redHome > 0 || view.redHomePermanent) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 4, cardsY + homeLine * lineStep, cardFont, view.redHomePermanent ? "R:PERM" : "R:" + view.formatShortTime(view.redHome), Graphics.TEXT_JUSTIFY_CENTER);
                homeLine += 1;
            }
            if (view.redAway > 0 || view.redAwayPermanent) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(3 * width / 4, cardsY + awayLine * lineStep, cardFont, view.redAwayPermanent ? "R:PERM" : "R:" + view.formatShortTime(view.redAway), Graphics.TEXT_JUSTIFY_CENTER);
                awayLine += 1;
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        return {:rows => maxCardRows, :lineStep => lineStep, :cardsY => cardsY};
    }

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

    static function calculateStateY(countdownY, layout, height) {
        // Anchor the state text slightly below the countdown timer, unless the reserved base position is lower.
        return (countdownY + height * 0.09 > layout[:stateBaseY]) ? countdownY + height * 0.09 : layout[:stateBaseY];
    }

    static function calculateHintY(stateY, hintBaseY, height) {
        // Keep the hint block beneath the state text or at the bottom hint base, whichever sits lower.
        return (stateY + height * 0.08 > hintBaseY) ? stateY + height * 0.08 : hintBaseY;
    }

    static function renderCountdown(dc, view, width, countdownFont, countdownY) {
        // Draw the large, white countdown digits centered so refs can still read the main clock even when the overlay
        // kicks in.
        var countdownStr = view.formatTime(view.countdownRemaining);
        dc.drawText(width / 2, countdownY, countdownFont, countdownStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    static function renderStateText(dc, view, width, stateFont, stateY, height) {
        // Each special state adopts a red accent, while the idle/paused text stays white for clarity.
        var stateColor = Graphics.COLOR_WHITE;
        if (view.gameState == STATE_CONVERSION || view.gameState == STATE_KICKOFF || view.gameState == STATE_PENALTY) {
            stateColor = Graphics.COLOR_RED;
        }
        dc.setColor(stateColor, Graphics.COLOR_TRANSPARENT);
        if (view.gameState == STATE_PAUSED) {
            dc.drawText(width / 2, stateY, stateFont, "PAUSED", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (view.gameState == STATE_CONVERSION) {
            dc.drawText(width / 2, stateY, stateFont, "CONVERSION", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, view.countdownSeconds.toLong().toString() + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (view.gameState == STATE_PENALTY) {
            dc.drawText(width / 2, stateY, stateFont, "PENALTY KICK", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, view.countdownSeconds.toLong().toString() + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (view.gameState == STATE_KICKOFF) {
            dc.drawText(width / 2, stateY, stateFont, "KICKOFF", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, view.countdownSeconds.toLong().toString() + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (view.gameState == STATE_HALFTIME) {
            dc.drawText(width / 2, stateY, stateFont, "HALF TIME", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (view.gameState == STATE_ENDED) {
            dc.drawText(width / 2, stateY, stateFont, "GAME ENDED", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (view.gameState == STATE_IDLE) {
            dc.drawText(width / 2, stateY, stateFont, "Ready to start", Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    static function renderHint(dc, view, width, hintFont, hintY) {
        var hint = "";
        if (view.gameState == STATE_IDLE) {
            hint = "SELECT: Start";
        } else if (view.gameState == STATE_PLAYING) {
            hint = "SELECT: Pause";
        } else if (view.gameState == STATE_PAUSED) {
            hint = "SELECT: Resume";
        }
        if (view.isLocked) {
            hint = "LOCKED";
        }
        var hintColor = view.dimMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE;
        dc.setColor(hintColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, hintY, hintFont, hint, Graphics.TEXT_JUSTIFY_CENTER);
    }

    static function renderSpecialOverlay(dc, view, width, height) {
        if (!view.specialTimerOverlayVisible || !view.isSpecialState()) {
            return;
        }
        var label = view.getSpecialStateLabel();
        var countdown = view.formatTime(view.countdownSeconds);
        var countdownMain = view.formatTime(view.countdownRemaining);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.04, Graphics.FONT_XTINY, "COUNTDOWN", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.12, Graphics.FONT_NUMBER_MEDIUM, countdownMain, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(view.getSpecialStateColor(), Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.32, Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.55, Graphics.FONT_NUMBER_HOT, countdown, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.80, Graphics.FONT_XTINY, view.getSpecialOverlayHint(), Graphics.TEXT_JUSTIFY_CENTER);
        if (view.specialOverlayMessage != null && System.getTimer() < view.specialOverlayMessageExpiry) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.65, Graphics.FONT_MEDIUM, view.specialOverlayMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}
