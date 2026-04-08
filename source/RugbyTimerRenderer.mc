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
            hintFont = Graphics.FONT_XTINY;
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

    static function chooseTeamLabelFont(width) {
        if (width <= 240) {
            return Graphics.FONT_SYSTEM_TINY;
        }
        return Graphics.FONT_SMALL;
    }

    static function chooseCompactScoreFont(width) {
        if (width <= 240) {
            return Graphics.FONT_LARGE;
        }
        return Graphics.FONT_NUMBER_MEDIUM;
    }

    /**
     * Compute the safe content bounds and measured bands for the live match screen.
     * @param dc The device context
     * @param width The screen width
     * @param height The screen height
     * @param fonts The chosen render fonts
     * @param guide The XML-backed layout guide
     * @return The measured layout values
     */
    static function hasTimedCompactCards(model) {
        if (model == null) {
            return false;
        }
        var timerNow = model.suspensionTime;
        if (!RugbyTimerCards.isNumeric(timerNow)) {
            timerNow = 0;
        }
        var timedGroups = [
            model.yellowHomeTimes,
            model.yellowAwayTimes,
            model.redHomePermanent ? null : model.redHomeTimes,
            model.redAwayPermanent ? null : model.redAwayTimes
        ];
        for (var i = 0; i < timedGroups.size(); i = i + 1) {
            var urgent = RugbyTimerRenderer.getUrgentCardEntry(timedGroups[i] as Lang.Array, timerNow);
            if (urgent != null) {
                return true;
            }
        }
        return false;
    }

    static function hasVisibleCompactSanctions(model) {
        if (RugbyTimerRenderer.hasTimedCompactCards(model)) {
            return true;
        }
        if (model == null) {
            return false;
        }
        return model.redHomePermanent || model.redAwayPermanent;
    }

    static function chooseCompactDetailMode(model, contentWidth, contentHeight) {
        if (RugbyTimerRenderer.hasTimedCompactCards(model)) {
            return "critical-only";
        }
        if (contentHeight >= 220 && contentWidth >= 205) {
            return "full-compact";
        }
        if (contentHeight >= 206) {
            return "critical-plus-elapsed-half";
        }
        if (contentHeight >= 176) {
            return "critical-plus-elapsed";
        }
        return "critical-only";
    }

    static function calculateLayout(dc, width, height, fonts, guide, model) {
        var layout = RugbyRenderLayout.create();
        var safeLeft = width * guide.safeSidePct;
        var safeRight = width - safeLeft;
        var safeTop = height * guide.safeTopPct;
        var safeBottom = height - (height * guide.safeBottomPct);
        var contentWidth = safeRight - safeLeft;
        var contentHeight = safeBottom - safeTop;
        var headerGap = height * guide.headerGapPct;
        var cardsGap = height * guide.cardsGapPct;
        var lowerBandGap = height * guide.lowerBandGapPct;
        var labelFont = RugbyTimerRenderer.chooseTeamLabelFont(width);
        var scoreFont = fonts.scoreFont;
        if (guide.family == "compact_round") {
            scoreFont = RugbyTimerRenderer.chooseCompactScoreFont(width);
        }
        var timerHeight = RugbyTimerRenderer.getFontHeightSafe(dc, fonts.timerFont, height * 0.04);
        var labelHeight = RugbyTimerRenderer.getFontHeightSafe(dc, labelFont, height * 0.03);
        var scoreHeight = RugbyTimerRenderer.getFontHeightSafe(dc, scoreFont, height * 0.10);
        var halfHeight = RugbyTimerRenderer.getFontHeightSafe(dc, fonts.halfFont, height * 0.03);
        var sanctionLineHeight = RugbyTimerRenderer.getFontHeightSafe(dc, Graphics.FONT_XTINY, height * 0.04) + (height * 0.016);
        var compactRound = guide.family == "compact_round";
        var showIcons = true;
        var showElapsedTimer = true;
        var showHalf = true;
        var showTries = true;
        var compactDetailMode = "standard";
        if (compactRound) {
            compactDetailMode = RugbyTimerRenderer.chooseCompactDetailMode(model, contentWidth, contentHeight);
            showIcons = false;
            showElapsedTimer = compactDetailMode != "critical-only";
            showHalf = compactDetailMode == "critical-plus-elapsed-half" || compactDetailMode == "full-compact";
            showTries = compactDetailMode == "full-compact";
        }
        var gameTimerY = safeTop;
        var teamLabelY = safeTop;
        if (showElapsedTimer) {
            teamLabelY = gameTimerY + timerHeight + headerGap;
        }
        var scoreGap = headerGap * 0.6;
        if (!showElapsedTimer) {
            scoreGap = headerGap * 0.35;
        }
        var scoreY = teamLabelY + labelHeight + scoreGap;
        var scoreBandBottomY = scoreY + scoreHeight;
        var triesY = scoreY + (scoreHeight * 0.42);
        var halfY = scoreBandBottomY + (height * 0.015);
        var headerBottomY = scoreBandBottomY;
        if (showHalf) {
            headerBottomY = halfY + halfHeight;
        }

        if (compactRound) {
            var previewRows = RugbyTimerRenderer.hasVisibleCompactSanctions(model) ? 1 : 0;
            var previewMiddleRoom = safeBottom - (height * guide.lowerBandGapPct) - (headerBottomY + cardsGap) - (previewRows * sanctionLineHeight);
            var previewCountdownHeight = RugbyTimerRenderer.getFontHeightSafe(dc, fonts.countdownFont, height * 0.22);
            if (compactDetailMode == "full-compact" && previewMiddleRoom < previewCountdownHeight + (height * 0.04)) {
                compactDetailMode = "critical-plus-elapsed-half";
                showTries = false;
            }
            if (compactDetailMode == "critical-plus-elapsed-half" && previewMiddleRoom < previewCountdownHeight + (height * 0.055)) {
                compactDetailMode = "critical-plus-elapsed";
                showHalf = false;
                headerBottomY = scoreBandBottomY;
            }
            if (compactDetailMode == "critical-plus-elapsed" && previewMiddleRoom < previewCountdownHeight + (height * 0.07)) {
                compactDetailMode = "critical-only";
                showElapsedTimer = false;
                teamLabelY = safeTop;
                scoreY = teamLabelY + labelHeight + (headerGap * 0.35);
                scoreBandBottomY = scoreY + scoreHeight;
                triesY = scoreY + (scoreHeight * 0.42);
                showHalf = false;
                showTries = false;
                headerBottomY = scoreBandBottomY;
            }
        }

        layout.family = guide.family;
        layout.compactDetailMode = compactDetailMode;
        layout.safeLeft = safeLeft;
        layout.safeRight = safeRight;
        layout.safeTop = safeTop;
        layout.safeBottom = safeBottom;
        layout.contentWidth = contentWidth;
        layout.contentHeight = contentHeight;
        layout.centerX = safeLeft + (contentWidth / 2);
        layout.homeScoreX = safeLeft + (contentWidth * 0.21);
        layout.awayScoreX = safeRight - (contentWidth * 0.21);
        var triesOffset = contentWidth * 0.12;
        if (compactRound) {
            triesOffset = contentWidth * 0.10;
        }
        layout.homeTriesX = layout.homeScoreX - triesOffset;
        layout.awayTriesX = layout.awayScoreX + triesOffset;
        layout.homeCardAnchorX = safeLeft + (contentWidth * guide.cardInsetPct);
        layout.awayCardAnchorX = safeRight - (contentWidth * guide.cardInsetPct);
        layout.gameTimerY = gameTimerY;
        layout.teamLabelY = teamLabelY;
        layout.scoreY = scoreY;
        layout.halfY = halfY;
        layout.triesY = triesY;
        layout.headerBottomY = headerBottomY;
        layout.cardsY = headerBottomY + cardsGap;
        layout.lowerBandTopY = safeBottom - lowerBandGap;
        layout.stateBaseY = layout.lowerBandTopY;
        layout.hintBaseY = safeBottom - RugbyTimerRenderer.getFontHeightSafe(dc, fonts.hintFont, height * 0.04);
        layout.iconY = safeTop;
        layout.showIcons = showIcons;
        layout.showElapsedTimer = showElapsedTimer;
        layout.showHalf = showHalf;
        layout.showTries = showTries;
        return layout;
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
        var topPadding = height * 0.03;
        var bottomPadding = height * 0.02;
        var afterCountdownGap = stateHeight > 0 ? height * 0.02 : height * 0.015;
        var afterStateGap = (stateHeight > 0 && hintHeight > 0) ? height * 0.015 : 0;
        var minCountdownY = layout.headerBottomY + (height * 0.02);
        var preferredCountdownY = cardStackBottom + topPadding;
        var maxCountdownY = layout.safeBottom - bottomPadding - hintHeight - afterStateGap - stateHeight - afterCountdownGap - countdownHeight;

        // On compact round screens the available middle band can be tighter than the
        // ideal gap budget. In that case, keep the countdown on-screen rather than
        // forcing it below the visible area.
        if (maxCountdownY < minCountdownY) {
            minCountdownY = maxCountdownY;
        }

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
     * @param height The height of the screen
     */
    static function renderScores(dc, model, layout, scoreFont, width) {
        var labelFont = RugbyTimerRenderer.chooseTeamLabelFont(width);
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(layout.homeScoreX, layout.teamLabelY, labelFont, "HOME", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(layout.awayScoreX, layout.teamLabelY, labelFont, "AWAY", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var compactScoreFont = scoreFont;
        if (layout.family == "compact_round") {
            compactScoreFont = RugbyTimerRenderer.chooseCompactScoreFont(width);
        }
        dc.drawText(layout.homeScoreX, layout.scoreY, compactScoreFont, model.homeScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(layout.awayScoreX, layout.scoreY, compactScoreFont, model.awayScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    /**
     * Renders the main game timer.
     * @param dc The device context
     * @param model The game model
     * @param width The width of the screen
     * @param timerFont The font to use for the timer
     * @param gameTimerY The Y position of the timer
     */
    static function renderGameTimer(dc, model, layout, timerFont) {
        if (!layout.showElapsedTimer) {
            return;
        }
        var gameStr = RugbyTimerTiming.formatTime(model.elapsedTime);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(layout.centerX, layout.gameTimerY, timerFont, gameStr, Graphics.TEXT_JUSTIFY_CENTER);
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
    static function renderHalfAndTries(dc, model, layout, halfFont, triesFont) {
        if (layout.showHalf) {
            var halfStr = "Half " + model.halfNumber.toString();
            dc.drawText(layout.centerX, layout.halfY, halfFont, halfStr, Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (layout.showTries) {
            dc.drawText(layout.homeTriesX, layout.triesY, triesFont, model.homeTries.toString() + "T", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(layout.awayTriesX, layout.triesY, triesFont, model.awayTries.toString() + "T", Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }

    /**
     * Renders the lock indicator.
     * @param dc The device context
     * @param view The view
     * @param width The width of the screen
     * @param halfFont The font to use for the lock indicator
     * @param scoreY The Y position of the lock indicator
     */
    static function renderLockIndicator(dc, layout, lockIcon) {
        if (layout.showIcons && lockIcon != null) {
            var iconX = layout.safeRight;
            try {
                iconX = iconX - lockIcon.getWidth();
            } catch (ex) {
                iconX = iconX - 12;
            }
            dc.drawBitmap(iconX, layout.iconY, lockIcon);
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
    static function renderPlayPauseIndicator(dc, model, layout, playIcon, pauseIcon) {
        if (!layout.showIcons) {
            return;
        }
        var icon = playIcon;
        if (model.gameState == STATE_PAUSED || model.gameState == STATE_IDLE) {
            icon = pauseIcon;
        }
        if (icon != null) {
            dc.drawBitmap(layout.safeLeft, layout.iconY, icon);
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

    static function getUrgentCardEntry(entries, timerNow) {
        if (entries == null) {
            return null;
        }
        var bestEntry = null;
        var bestRemaining = null;
        for (var i = 0; i < entries.size(); i = i + 1) {
            var entry = CardEntry.fromDict(entries[i]);
            if (entry == null) {
                continue;
            }
            var remaining = entry.remaining;
            if (!RugbyTimerCards.isNumeric(remaining)) {
                remaining = RugbyTimerCards.getEntryRemaining(entry, timerNow);
            }
            if (!RugbyTimerCards.isNumeric(remaining) || remaining <= 0) {
                continue;
            }
            if (bestRemaining == null || remaining < bestRemaining) {
                bestRemaining = remaining;
                bestEntry = entry;
                bestEntry.remaining = remaining;
            }
        }
        return bestEntry;
    }

    static function renderUrgentTeamCard(dc, model, rowY, labelFont, valueFont, labelX, timerX, cardEntry, cardColor) {
        if (cardEntry == null) {
            return false;
        }
        var prefix = "Y";
        var fallbackId = 1;
        if (cardColor == Graphics.COLOR_RED) {
            prefix = "R";
        }
        if (cardEntry.cardId instanceof Lang.Number || cardEntry.cardId instanceof Lang.Float) {
            fallbackId = cardEntry.cardId;
        }
        var label = RugbyTimerRenderer.canonicalCardLabel(cardEntry.label, prefix, fallbackId);
        RugbyTimerRenderer.renderCardRow(
            dc,
            labelX,
            timerX,
            rowY,
            labelFont,
            valueFont,
            cardColor,
            label,
            model.formatShortTime(RugbyTimerTiming.getDisplayCountdownSeconds(cardEntry.remaining))
        );
        return true;
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
    static function renderCardTimers(dc, model, layout, height) {
        Profiler.start("renderCardTimers");
        // Only render the first two active sanctions per team so the primary layout stays tidy while
        // extra yellow/red timers continue counting in the background.
        if (model.yellowHomeTimes == null) { model.yellowHomeTimes = []; }
        if (model.yellowAwayTimes == null) { model.yellowAwayTimes = []; }
        var timerNow = model.suspensionTime;
        if (!(timerNow instanceof Lang.Number) && !(timerNow instanceof Lang.Float)) {
            timerNow = 0;
        }
        var urgentHomeYellow = RugbyTimerRenderer.getUrgentCardEntry(model.yellowHomeTimes as Lang.Array, timerNow);
        var urgentAwayYellow = RugbyTimerRenderer.getUrgentCardEntry(model.yellowAwayTimes as Lang.Array, timerNow);
        var urgentHomeRed = null;
        if (!model.redHomePermanent) {
            urgentHomeRed = RugbyTimerRenderer.getUrgentCardEntry(model.redHomeTimes as Lang.Array, timerNow);
        }
        var urgentAwayRed = null;
        if (!model.redAwayPermanent) {
            urgentAwayRed = RugbyTimerRenderer.getUrgentCardEntry(model.redAwayTimes as Lang.Array, timerNow);
        }
        var homeCardRows = 0;
        if (urgentHomeYellow != null || urgentHomeRed != null || model.redHomePermanent) { homeCardRows = 1; }
        var awayCardRows = 0;
        if (urgentAwayYellow != null || urgentAwayRed != null || model.redAwayPermanent) { awayCardRows = 1; }
        var maxCardRows = (homeCardRows > awayCardRows) ? homeCardRows : awayCardRows;
        var lineStep = height * 0.065;
        if (maxCardRows > 0) {
            var width = layout.safeRight - layout.safeLeft;
            var homeX = layout.homeCardAnchorX;
            var awayX = layout.awayCardAnchorX;
            var labelFont = width <= 220 ? Graphics.FONT_XTINY : Graphics.FONT_SMALL;
            var valueFont = labelFont;
            var maxLabelHeight = RugbyTimerRenderer.getFontHeightSafe(dc, labelFont, height * 0.04);
            var maxValueHeight = RugbyTimerRenderer.getFontHeightSafe(dc, valueFont, height * 0.04);
            var maxFontHeight = (maxValueHeight > maxLabelHeight) ? maxValueHeight : maxLabelHeight;
            lineStep = maxFontHeight + (height * 0.016);
            var labelGap = width * 0.016;
            var timerGap = width * 0.026;
            var homeLabelX = homeX - labelGap;
            var homeTimerX = homeX + timerGap;
            var awayLabelX = awayX - labelGap;
            var awayTimerX = awayX + timerGap;
            var homeBest = urgentHomeYellow;
            var homeBestColor = Graphics.COLOR_YELLOW;
            if (urgentHomeRed != null && (homeBest == null || urgentHomeRed.remaining < homeBest.remaining)) {
                homeBest = urgentHomeRed;
                homeBestColor = Graphics.COLOR_RED;
            }
            var awayBest = urgentAwayYellow;
            var awayBestColor = Graphics.COLOR_YELLOW;
            if (urgentAwayRed != null && (awayBest == null || urgentAwayRed.remaining < awayBest.remaining)) {
                awayBest = urgentAwayRed;
                awayBestColor = Graphics.COLOR_RED;
            }

            var homeRendered = RugbyTimerRenderer.renderUrgentTeamCard(dc, model, layout.cardsY, labelFont, valueFont, homeLabelX, homeTimerX, homeBest, homeBestColor);
            if (!homeRendered && model.redHomePermanent) {
                var redPermHomeLabel = model.redHomeLabelCounter > 0 ? "R" + model.redHomeLabelCounter.toString() : "R";
                RugbyTimerRenderer.renderCardRow(
                    dc,
                    homeLabelX,
                    homeTimerX,
                    layout.cardsY,
                    labelFont,
                    valueFont,
                    Graphics.COLOR_RED,
                    redPermHomeLabel,
                    "PERM"
                );
            }

            var awayRendered = RugbyTimerRenderer.renderUrgentTeamCard(dc, model, layout.cardsY, labelFont, valueFont, awayLabelX, awayTimerX, awayBest, awayBestColor);
            if (!awayRendered && model.redAwayPermanent) {
                var redPermAwayLabel = model.redAwayLabelCounter > 0 ? "R" + model.redAwayLabelCounter.toString() : "R";
                RugbyTimerRenderer.renderCardRow(
                    dc,
                    awayLabelX,
                    awayTimerX,
                    layout.cardsY,
                    labelFont,
                    valueFont,
                    Graphics.COLOR_RED,
                    redPermAwayLabel,
                    "PERM"
                );
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        Profiler.stop("renderCardTimers");
        return RugbyRenderedCardInfo.create(maxCardRows, lineStep, layout.cardsY);
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
    static function renderCountdown(dc, model, layout, countdownFont, countdownY) {
        Profiler.start("renderCountdown");
        // Draw the large, white countdown digits centered so refs can still read the main clock even when the overlay
        // kicks in.
        var displaySeconds = RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownRemaining);
        var countdownStr = RugbyTimerTiming.formatTime(displaySeconds);
        dc.drawText(layout.centerX, countdownY, countdownFont, countdownStr, Graphics.TEXT_JUSTIFY_CENTER);
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
    static function renderStateText(dc, model, centerX, stateFont, stateY, height) {
        // Paused and special states adopt a red accent so they stand out from normal match play.
        var stateColor = Graphics.COLOR_WHITE;
        if (model.gameState == STATE_PAUSED || model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY) {
            stateColor = Graphics.COLOR_RED;
        }
        dc.setColor(stateColor, Graphics.COLOR_TRANSPARENT);
        if (model.gameState == STATE_PAUSED) {
            dc.drawText(centerX, stateY, Graphics.FONT_SMALL, "PAUSED", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_CONVERSION) {
            dc.drawText(centerX, stateY, stateFont, "CONVERSION", Graphics.TEXT_JUSTIFY_CENTER);
            var convSeconds = RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownSeconds);
            var countdownStr = (convSeconds as Lang.Number).toLong().toString();
            dc.drawText(centerX, stateY + (height * 0.07), stateFont, countdownStr + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_PENALTY) {
            dc.drawText(centerX, stateY, stateFont, "PENALTY KICK", Graphics.TEXT_JUSTIFY_CENTER);
            var penSeconds = RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownSeconds);
            var countdownStr = (penSeconds as Lang.Number).toLong().toString();
            dc.drawText(centerX, stateY + (height * 0.07), stateFont, countdownStr + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_HALFTIME) {
            dc.drawText(centerX, stateY, stateFont, "HALF TIME", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_ENDED) {
            dc.drawText(centerX, stateY, stateFont, "GAME ENDED", Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

}
