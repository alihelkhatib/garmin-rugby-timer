using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Rez.Drawables;

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
            stateFont = Graphics.FONT_XTINY;
            hintFont = Graphics.FONT_SYSTEM_TINY;
        } else if (width <= 260) {
            scoreFont = Graphics.FONT_NUMBER_MEDIUM;
            triesFont = Graphics.FONT_XTINY;
            halfFont = Graphics.FONT_XTINY;
            timerFont = Graphics.FONT_SYSTEM_TINY;
            countdownFont = Graphics.FONT_NUMBER_HOT;
            stateFont = Graphics.FONT_XTINY;
            hintFont = Graphics.FONT_SYSTEM_TINY;
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
        var cardsY = height * 0.31;
        var stateBaseY = height * 0.86;
        var hintBaseY = height * 0.93;
        var iconY = height * 0.04;
        return {
            :scoreY => scoreY,
            :halfY => halfY,
            :gameTimerY => gameTimerY,
            :triesY => triesY,
            :cardsY => cardsY,
            :stateBaseY => stateBaseY,
            :hintBaseY => hintBaseY,
            :iconY => iconY
        };
    }

    static function getFontHeightSafe(dc, font, fallback) {
        try {
            var fontHeight = dc.getFontHeight(font);
            if (fontHeight instanceof Lang.Number || fontHeight instanceof Lang.Float) {
                if (fontHeight > 0) {
                    return fontHeight;
                }
            }
        } catch (ex) {
        }
        return fallback;
    }

    static function calculateMainContentLayout(dc, model, fonts, layout, cardInfo, height, isLocked) {
        var countdownHeight = RugbyTimerRenderer.getFontHeightSafe(dc, fonts[:countdownFont], height * 0.22);
        var stateHeight = 0;
        if (model.gameState == STATE_PAUSED) {
            stateHeight = RugbyTimerRenderer.getFontHeightSafe(dc, Graphics.FONT_SMALL, height * 0.06);
        } else if (model.gameState == STATE_HALFTIME || model.gameState == STATE_ENDED) {
            stateHeight = RugbyTimerRenderer.getFontHeightSafe(dc, fonts[:stateFont], height * 0.05);
        }

        var hintLines = 0;
        if (isLocked) {
            hintLines = 1;
        } else if (model.gameState == STATE_IDLE) {
            hintLines = 2;
        } else if (model.gameState == STATE_PLAYING) {
            hintLines = 1;
        }

        var hintLineHeight = RugbyTimerRenderer.getFontHeightSafe(dc, fonts[:hintFont], height * 0.04);
        var hintLineGap = hintLineHeight + (height * 0.012);
        var hintHeight = 0;
        if (hintLines > 0) {
            hintHeight = hintLineHeight;
            if (hintLines > 1) {
                hintHeight = hintHeight + ((hintLines - 1) * hintLineGap);
            }
        }

        var cardStackBottom = cardInfo[:cardsY] + (cardInfo[:rows] * cardInfo[:lineStep]);
        var topPadding = height * 0.05;
        var bottomPadding = height * 0.08;
        var afterCountdownGap = stateHeight > 0 ? height * 0.02 : height * 0.015;
        var afterStateGap = (stateHeight > 0 && hintHeight > 0) ? height * 0.015 : 0;
        var minCountdownY = layout[:triesY] + height * 0.08;
        var preferredCountdownY = cardStackBottom + topPadding;
        var maxCountdownY = height - bottomPadding - hintHeight - afterStateGap - stateHeight - afterCountdownGap - countdownHeight;

        if (preferredCountdownY < minCountdownY) {
            preferredCountdownY = minCountdownY;
        }
        if (preferredCountdownY > maxCountdownY) {
            preferredCountdownY = maxCountdownY;
        }
        if (preferredCountdownY < minCountdownY) {
            preferredCountdownY = minCountdownY;
        }

        var stateY = preferredCountdownY + countdownHeight + afterCountdownGap;
        var hintY = preferredCountdownY + countdownHeight + afterCountdownGap;
        if (stateHeight > 0) {
            hintY = stateY + stateHeight + afterStateGap;
        }

        return {
            :countdownY => preferredCountdownY,
            :stateY => stateY,
            :hintY => hintY,
            :hintLineGap => hintLineGap
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
        var gameStr = RugbyTimerTiming.formatTime(model.elapsedTime);
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
    static function renderLockIndicator(dc, width, height, scoreY) {
        var iconMarginX = width * 0.08;
        var iconY = scoreY - height * 0.05;
        if (iconY < 0) { iconY = 0; }
        var lockIcon = WatchUi.loadResource(Rez.Drawables.LockIcon) as WatchUi.BitmapResource;
        if (lockIcon != null) {
            dc.drawBitmap(width - iconMarginX, iconY, lockIcon);
        }
    }

    /**
     * Renders the play/pause indicator.
     * @param dc The device context
     * @param model The game model
     * @param width The width of the screen
     * @param height The height of the screen
     * @param iconY The Y position of the icon
     */
    static function renderPlayPauseIndicator(dc, model, width, height, iconY) {
        var iconMarginX = width * 0.08;
        var y = iconY;
        if (y < 0) { y = 0; }
        var iconId = Rez.Drawables.PlayIcon;
        if (model.gameState == STATE_PAUSED || model.gameState == STATE_IDLE) {
            iconId = Rez.Drawables.PauseIcon;
        }
        var icon = WatchUi.loadResource(iconId) as WatchUi.BitmapResource;
        if (icon != null) {
            dc.drawBitmap(iconMarginX, y, icon);
        }
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
        // Only render the first two active sanctions per team so the primary layout stays tidy while
        // extra yellow/red timers continue counting in the background.
        if (model.yellowHomeTimes == null) { model.yellowHomeTimes = []; }
        if (model.yellowAwayTimes == null) { model.yellowAwayTimes = []; }
        var timerNow = model.suspensionTime;
        if (!(timerNow instanceof Lang.Number) && !(timerNow instanceof Lang.Float)) {
            timerNow = 0;
        }
        var visibleYellowHome = model.yellowHomeTimes.size();
        var visibleYellowAway = model.yellowAwayTimes.size();
        var visibleRedHome = model.redHomePermanent ? 1 : model.redHomeTimes.size();
        var visibleRedAway = model.redAwayPermanent ? 1 : model.redAwayTimes.size();
        var homeCardRows = visibleYellowHome + visibleRedHome;
        var awayCardRows = visibleYellowAway + visibleRedAway;
        if (homeCardRows > 2) { homeCardRows = 2; }
        if (awayCardRows > 2) { awayCardRows = 2; }
        var maxCardRows = (homeCardRows > awayCardRows) ? homeCardRows : awayCardRows;
        var lineStep = height * 0.065;
        if (maxCardRows > 0) {
            var homeLine = 0;
            var awayLine = 0;
            var homeX = width / 4;
            var awayX = (3 * width) / 4;
            var cardFont = width <= 260 ? Graphics.FONT_XTINY : Graphics.FONT_SMALL;
            var cardFontRed = cardFont;
            var maxFontHeight = RugbyTimerRenderer.getFontHeightSafe(dc, cardFont, height * 0.04);
            lineStep = maxFontHeight + (height * 0.010);
            var homeVisibleCount = 0;
            var awayVisibleCount = 0;
            for (var i = 0; i < model.yellowHomeTimes.size(); i = i + 1) {
                if (homeVisibleCount >= 2) {
                    break;
                }
                var entry = model.yellowHomeTimes[i] as Lang.Dictionary;
                if (entry == null) {
                    continue;
                }
                var y = entry["remaining"];
                if (!(y instanceof Lang.Number) && !(y instanceof Lang.Float)) {
                    y = RugbyTimerCards.getEntryRemaining(entry, timerNow);
                }
                var label = entry["label"];
                if (label == null) {
                    label = "Y" + (homeLine + 1).toString();
                }
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(homeX, cardsY + homeLine * lineStep, cardFont, label + ":" + model.formatShortTime(RugbyTimerTiming.getDisplayCountdownSeconds(y)), Graphics.TEXT_JUSTIFY_CENTER);
                homeVisibleCount += 1;
                homeLine += 1;
            }
            for (var i = 0; i < model.yellowAwayTimes.size(); i = i + 1) {
                if (awayVisibleCount >= 2) {
                    break;
                }
                var entry = model.yellowAwayTimes[i] as Lang.Dictionary;
                if (entry == null) {
                    continue;
                }
                var y2 = entry["remaining"];
                if (!(y2 instanceof Lang.Number) && !(y2 instanceof Lang.Float)) {
                    y2 = RugbyTimerCards.getEntryRemaining(entry, timerNow);
                }
                var label2 = entry["label"];
                if (label2 == null) {
                    label2 = "Y" + (awayLine + 1).toString();
                }
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(awayX, cardsY + awayLine * lineStep, cardFont, label2 + ":" + model.formatShortTime(RugbyTimerTiming.getDisplayCountdownSeconds(y2)), Graphics.TEXT_JUSTIFY_CENTER);
                awayVisibleCount += 1;
                awayLine += 1;
            }
            if (model.redHomePermanent && homeVisibleCount < 2) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                var redPermHomeLabel = model.redHomeLabelCounter > 0 ? "R" + model.redHomeLabelCounter.toString() + ":PERM" : "R:PERM";
                dc.drawText(homeX, cardsY + homeLine * lineStep, cardFontRed, redPermHomeLabel, Graphics.TEXT_JUSTIFY_CENTER);
                homeVisibleCount += 1;
                homeLine += 1;
            } else {
                for (var i = 0; i < model.redHomeTimes.size(); i = i + 1) {
                    if (homeVisibleCount >= 2) {
                        break;
                    }
                    var redHomeEntry = model.redHomeTimes[i] as Lang.Dictionary;
                    if (redHomeEntry == null) {
                        continue;
                    }
                    var redHomeRem = redHomeEntry["remaining"];
                    if (!(redHomeRem instanceof Lang.Number) && !(redHomeRem instanceof Lang.Float)) {
                        redHomeRem = RugbyTimerCards.getEntryRemaining(redHomeEntry, timerNow);
                    }
                    var redHomeLabel = redHomeEntry["label"];
                    if (redHomeLabel == null) {
                        redHomeLabel = "R" + (i + 1).toString();
                    }
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(homeX, cardsY + homeLine * lineStep, cardFontRed, redHomeLabel + ":" + model.formatShortTime(RugbyTimerTiming.getDisplayCountdownSeconds(redHomeRem)), Graphics.TEXT_JUSTIFY_CENTER);
                    homeVisibleCount += 1;
                    homeLine += 1;
                }
            }
            if (model.redAwayPermanent && awayVisibleCount < 2) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                var redPermAwayLabel = model.redAwayLabelCounter > 0 ? "R" + model.redAwayLabelCounter.toString() + ":PERM" : "R:PERM";
                dc.drawText(awayX, cardsY + awayLine * lineStep, cardFontRed, redPermAwayLabel, Graphics.TEXT_JUSTIFY_CENTER);
                awayVisibleCount += 1;
                awayLine += 1;
            } else {
                for (var i = 0; i < model.redAwayTimes.size(); i = i + 1) {
                    if (awayVisibleCount >= 2) {
                        break;
                    }
                    var redAwayEntry = model.redAwayTimes[i] as Lang.Dictionary;
                    if (redAwayEntry == null) {
                        continue;
                    }
                    var redAwayRem = redAwayEntry["remaining"];
                    if (!(redAwayRem instanceof Lang.Number) && !(redAwayRem instanceof Lang.Float)) {
                        redAwayRem = RugbyTimerCards.getEntryRemaining(redAwayEntry, timerNow);
                    }
                    var redAwayLabel = redAwayEntry["label"];
                    if (redAwayLabel == null) {
                        redAwayLabel = "R" + (i + 1).toString();
                    }
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(awayX, cardsY + awayLine * lineStep, cardFontRed, redAwayLabel + ":" + model.formatShortTime(RugbyTimerTiming.getDisplayCountdownSeconds(redAwayRem)), Graphics.TEXT_JUSTIFY_CENTER);
                    awayVisibleCount += 1;
                    awayLine += 1;
                }
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
        var countdownCandidate = cardStackBottom + height * 0.06;
        var countdownLimit = layout[:stateBaseY] - height * 0.22;
        var countdownMin = layout[:triesY] + height * 0.08;
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
        return (countdownY + height * 0.12 > layout[:stateBaseY]) ? countdownY + height * 0.12 : layout[:stateBaseY];
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
        return (stateY + height * 0.06 > hintBaseY) ? stateY + height * 0.06 : hintBaseY;
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
        var displaySeconds = RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownRemaining);
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
        // Paused and special states adopt a red accent so they stand out from normal match play.
        var stateColor = Graphics.COLOR_WHITE;
        if (model.gameState == STATE_PAUSED || model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY) {
            stateColor = Graphics.COLOR_RED;
        }
        dc.setColor(stateColor, Graphics.COLOR_TRANSPARENT);
        if (model.gameState == STATE_PAUSED) {
            dc.drawText(width / 2, stateY, Graphics.FONT_SMALL, "PAUSED", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_CONVERSION) {
            dc.drawText(width / 2, stateY, stateFont, "CONVERSION", Graphics.TEXT_JUSTIFY_CENTER);
            var convSeconds = RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownSeconds);
            var countdownStr = (convSeconds as Lang.Number).toLong().toString();
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, countdownStr + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_PENALTY) {
            dc.drawText(width / 2, stateY, stateFont, "PENALTY KICK", Graphics.TEXT_JUSTIFY_CENTER);
            var penSeconds = RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownSeconds);
            var countdownStr = (penSeconds as Lang.Number).toLong().toString();
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, countdownStr + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_HALFTIME) {
            dc.drawText(width / 2, stateY, stateFont, "HALF TIME", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_ENDED) {
            dc.drawText(width / 2, stateY, stateFont, "GAME ENDED", Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

}
