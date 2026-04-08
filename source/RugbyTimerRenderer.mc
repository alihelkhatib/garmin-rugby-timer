using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Rez.Drawables;

/**
 * Main match-screen renderer.
 *
 * Purpose: compute layout/font decisions and draw the standard scoreboard,
 * clocks, hints, and card stacks so `RugbyTimerView` stays focused on view state.
 */
class RugbyTimerRenderer {
    static function invalidateMainLayoutCache() {
        // No-op. Layout caching was removed to avoid container-analysis noise
        // and startup/runtime complexity in a small render helper.
    }

    static function getMainContentLayoutCached(dc, model, fonts, layout, cardInfo, height, isLocked) {
        return RugbyTimerRenderer.calculateMainContentLayout(dc, model, fonts, layout, cardInfo, height, isLocked);
    }
    /**
     * Central rendering helper that keeps layout math and font selection in one place so
     * the view can focus on state updates and overlays.
     * @param width The width of the screen
     * @return A dictionary of fonts
     */
    static function chooseFonts(width) {
        // Compute fonts for the given width. Caching removed in test scaffold to avoid
        // static-init issues; we can reintroduce caching later behind a safe guard.
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
        return RugbyRenderFonts.create(scoreFont, triesFont, halfFont, timerFont, countdownFont, stateFont, hintFont);
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
        return RugbyRenderLayout.create(scoreY, halfY, gameTimerY, triesY, cardsY, stateBaseY, hintBaseY, iconY);
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
        var countdownHeight = RugbyTimerRenderer.getFontHeightSafe(dc, fonts.countdownFont, height * 0.22);
        var stateHeight = 0;
        if (model.gameState == STATE_PAUSED || model.gameState == STATE_PLAYING) {
            stateHeight = RugbyTimerRenderer.getFontHeightSafe(dc, Graphics.FONT_SMALL, height * 0.06);
        } else if (model.gameState == STATE_HALFTIME || model.gameState == STATE_ENDED) {
            stateHeight = RugbyTimerRenderer.getFontHeightSafe(dc, fonts.stateFont, height * 0.05);
        }

        var hintLines = 0;
        if (isLocked) {
            hintLines = 1;
        } else if (model.gameState == STATE_IDLE) {
            hintLines = 2;
        } else if (model.gameState == STATE_PLAYING) {
            hintLines = 1;
        }

        // Reserve the same bottom-band height across idle, playing, and paused so the
        // main countdown does not jump when hint/state text appears or disappears.
        var reservedHintLines = hintLines;
        if (!isLocked && (model.gameState == STATE_IDLE || model.gameState == STATE_PLAYING || model.gameState == STATE_PAUSED)) {
            reservedHintLines = 2;
        }

        var hintLineHeight = RugbyTimerRenderer.getFontHeightSafe(dc, fonts.hintFont, height * 0.04);
        var hintLineGap = hintLineHeight + (height * 0.012);
        var hintHeight = 0;
        if (reservedHintLines > 0) {
            hintHeight = hintLineHeight;
            if (reservedHintLines > 1) {
                hintHeight = hintHeight + ((reservedHintLines - 1) * hintLineGap);
            }
        }

        var cardStackBottom = cardInfo.cardsY + (cardInfo.rows * cardInfo.lineStep);
        var topPadding = height * 0.05;
        var bottomPadding = height * 0.08;
        var afterCountdownGap = stateHeight > 0 ? height * 0.02 : height * 0.015;
        var afterStateGap = (stateHeight > 0 && hintHeight > 0) ? height * 0.015 : 0;
        var minCountdownY = layout.triesY + height * 0.08;
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

        return RugbyMainContentLayout.create(preferredCountdownY, stateY, hintY, hintLineGap);
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
    static function renderLockIndicator(dc, width, height, scoreY, lockIcon) {
        var iconMarginX = width * 0.08;
        var iconY = scoreY - height * 0.05;
        if (iconY < 0) { iconY = 0; }
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
    static function renderPlayPauseIndicator(dc, model, width, height, iconY, playIcon, pauseIcon) {
        var iconMarginX = width * 0.08;
        var y = iconY;
        if (y < 0) { y = 0; }
        var icon = playIcon;
        if (model.gameState == STATE_PAUSED || model.gameState == STATE_IDLE) {
            icon = pauseIcon;
        }
        if (icon != null) {
            dc.drawBitmap(iconMarginX, y, icon);
        }
    }

    static function canonicalCardLabel(label, prefix, fallbackId) {
        if (label instanceof Lang.String) {
            var normalized = label;
            while (normalized.length() > 0 && normalized.substring(0, 1) == " ") {
                normalized = normalized.substring(1, normalized.length());
            }
            while (normalized.length() > 0 && normalized.substring(normalized.length() - 1, normalized.length()) == " ") {
                normalized = normalized.substring(0, normalized.length() - 1);
            }
            if (normalized.length() > 0) {
                return normalized;
            }
        }
        return prefix + fallbackId.toString();
    }

    static function renderCardRow(dc, labelX, timerX, rowY, labelFont, valueFont, labelColor, labelText, valueText) {
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(labelX, rowY, labelFont, labelText, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(timerX, rowY, valueFont, valueText, Graphics.TEXT_JUSTIFY_LEFT);
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
        Profiler.start("renderCardTimers");
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
            var labelFont = width <= 260 ? Graphics.FONT_XTINY : Graphics.FONT_SMALL;
            var valueFont = width <= 260 ? Graphics.FONT_TINY : Graphics.FONT_SMALL;
            var maxLabelHeight = RugbyTimerRenderer.getFontHeightSafe(dc, labelFont, height * 0.04);
            var maxValueHeight = RugbyTimerRenderer.getFontHeightSafe(dc, valueFont, height * 0.045);
            var maxFontHeight = (maxValueHeight > maxLabelHeight) ? maxValueHeight : maxLabelHeight;
            lineStep = maxFontHeight + (height * 0.016);
            var labelGap = width * 0.016;
            var timerGap = width * 0.026;
            var homeLabelX = homeX - labelGap;
            var homeTimerX = homeX + timerGap;
            var awayLabelX = awayX - labelGap;
            var awayTimerX = awayX + timerGap;
            var homeVisibleCount = 0;
            var awayVisibleCount = 0;
            var homeYellowEntries = model.yellowHomeTimes as Lang.Array;
            for (var i = 0; i < homeYellowEntries.size(); i = i + 1) {
                if (homeVisibleCount >= 2) {
                    break;
                }
                var entry = CardEntry.fromDict(homeYellowEntries[i]);
                if (entry == null) {
                    continue;
                }
                var y = entry.remaining;
                if (!(y instanceof Lang.Number) && !(y instanceof Lang.Float)) {
                    y = RugbyTimerCards.getEntryRemaining(entry, timerNow);
                }
                var label = RugbyTimerRenderer.canonicalCardLabel(entry.label, "Y", homeLine + 1);
                RugbyTimerRenderer.renderCardRow(
                    dc,
                    homeLabelX,
                    homeTimerX,
                    cardsY + homeLine * lineStep,
                    labelFont,
                    valueFont,
                    Graphics.COLOR_YELLOW,
                    label,
                    model.formatShortTime(RugbyTimerTiming.getDisplayCountdownSeconds(y))
                );
                homeVisibleCount += 1;
                homeLine += 1;
            }
            var awayYellowEntries = model.yellowAwayTimes as Lang.Array;
            for (var i = 0; i < awayYellowEntries.size(); i = i + 1) {
                if (awayVisibleCount >= 2) {
                    break;
                }
                var entry = CardEntry.fromDict(awayYellowEntries[i]);
                if (entry == null) {
                    continue;
                }
                var y2 = entry.remaining;
                if (!(y2 instanceof Lang.Number) && !(y2 instanceof Lang.Float)) {
                    y2 = RugbyTimerCards.getEntryRemaining(entry, timerNow);
                }
                var label2 = RugbyTimerRenderer.canonicalCardLabel(entry.label, "Y", awayLine + 1);
                RugbyTimerRenderer.renderCardRow(
                    dc,
                    awayLabelX,
                    awayTimerX,
                    cardsY + awayLine * lineStep,
                    labelFont,
                    valueFont,
                    Graphics.COLOR_YELLOW,
                    label2,
                    model.formatShortTime(RugbyTimerTiming.getDisplayCountdownSeconds(y2))
                );
                awayVisibleCount += 1;
                awayLine += 1;
            }
            if (model.redHomePermanent && homeVisibleCount < 2) {
                var redPermHomeLabel = model.redHomeLabelCounter > 0 ? "R" + model.redHomeLabelCounter.toString() : "R";
                RugbyTimerRenderer.renderCardRow(
                    dc,
                    homeLabelX,
                    homeTimerX,
                    cardsY + homeLine * lineStep,
                    labelFont,
                    valueFont,
                    Graphics.COLOR_RED,
                    redPermHomeLabel,
                    "PERM"
                );
                homeVisibleCount += 1;
                homeLine += 1;
            } else {
                var redHomeEntries = model.redHomeTimes as Lang.Array;
                for (var i = 0; i < redHomeEntries.size(); i = i + 1) {
                    if (homeVisibleCount >= 2) {
                        break;
                    }
                    var redHomeEntry = CardEntry.fromDict(redHomeEntries[i]);
                    if (redHomeEntry == null) {
                        continue;
                    }
                    var redHomeRem = redHomeEntry.remaining;
                    if (!(redHomeRem instanceof Lang.Number) && !(redHomeRem instanceof Lang.Float)) {
                        redHomeRem = RugbyTimerCards.getEntryRemaining(redHomeEntry, timerNow);
                    }
                    var redHomeLabel = RugbyTimerRenderer.canonicalCardLabel(redHomeEntry.label, "R", i + 1);
                    RugbyTimerRenderer.renderCardRow(
                        dc,
                        homeLabelX,
                        homeTimerX,
                        cardsY + homeLine * lineStep,
                        labelFont,
                        valueFont,
                        Graphics.COLOR_RED,
                        redHomeLabel,
                        model.formatShortTime(RugbyTimerTiming.getDisplayCountdownSeconds(redHomeRem))
                    );
                    homeVisibleCount += 1;
                    homeLine += 1;
                }
            }
            if (model.redAwayPermanent && awayVisibleCount < 2) {
                var redPermAwayLabel = model.redAwayLabelCounter > 0 ? "R" + model.redAwayLabelCounter.toString() : "R";
                RugbyTimerRenderer.renderCardRow(
                    dc,
                    awayLabelX,
                    awayTimerX,
                    cardsY + awayLine * lineStep,
                    labelFont,
                    valueFont,
                    Graphics.COLOR_RED,
                    redPermAwayLabel,
                    "PERM"
                );
                awayVisibleCount += 1;
                awayLine += 1;
            } else {
                var redAwayEntries = model.redAwayTimes as Lang.Array;
                for (var i = 0; i < redAwayEntries.size(); i = i + 1) {
                    if (awayVisibleCount >= 2) {
                        break;
                    }
                    var redAwayEntry = CardEntry.fromDict(redAwayEntries[i]);
                    if (redAwayEntry == null) {
                        continue;
                    }
                    var redAwayRem = redAwayEntry.remaining;
                    if (!(redAwayRem instanceof Lang.Number) && !(redAwayRem instanceof Lang.Float)) {
                        redAwayRem = RugbyTimerCards.getEntryRemaining(redAwayEntry, timerNow);
                    }
                    var redAwayLabel = RugbyTimerRenderer.canonicalCardLabel(redAwayEntry.label, "R", i + 1);
                    RugbyTimerRenderer.renderCardRow(
                        dc,
                        awayLabelX,
                        awayTimerX,
                        cardsY + awayLine * lineStep,
                        labelFont,
                        valueFont,
                        Graphics.COLOR_RED,
                        redAwayLabel,
                        model.formatShortTime(RugbyTimerTiming.getDisplayCountdownSeconds(redAwayRem))
                    );
                    awayVisibleCount += 1;
                    awayLine += 1;
                }
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        Profiler.stop("renderCardTimers");
        return RugbyRenderedCardInfo.create(maxCardRows, lineStep, cardsY);
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
        var cardStackBottom = cardInfo.cardsY + (cardInfo.rows * cardInfo.lineStep);
        var countdownCandidate = cardStackBottom + height * 0.06;
        var countdownLimit = layout.stateBaseY - height * 0.22;
        var countdownMin = layout.triesY + height * 0.08;
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
        return (countdownY + height * 0.12 > layout.stateBaseY) ? countdownY + height * 0.12 : layout.stateBaseY;
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
        Profiler.start("renderCountdown");
        // Draw the large, white countdown digits centered so refs can still read the main clock even when the overlay
        // kicks in.
        var displaySeconds = RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownRemaining);
        var countdownStr = RugbyTimerTiming.formatTime(displaySeconds);
        dc.drawText(width / 2, countdownY, countdownFont, countdownStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        Profiler.stop("renderCountdown");
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
