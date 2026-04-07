using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
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
        var scoreY = height * 0.11;
        var halfY = height * 0.185;
        var gameTimerY = height * 0.075;
        var triesY = halfY + height * 0.045;
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
        if (model.gameState == STATE_PAUSED) {
            stateHeight = RugbyTimerRenderer.getFontHeightSafe(dc, Graphics.FONT_SMALL, height * 0.06);
        } else if (model.gameState == STATE_HALFTIME || model.gameState == STATE_ENDED) {
            stateHeight = RugbyTimerRenderer.getFontHeightSafe(dc, fonts.stateFont, height * 0.05);
        }

        var hintLines = 0;
        if (isLocked) {
            hintLines = 1;
        } else if (model.gameState == STATE_IDLE) {
            // Idle mode renders two separate help rows: adjustment plus start.
            hintLines = 2;
        } else if (model.gameState == STATE_PLAYING) {
            hintLines = 1;
        }

        var hintLineHeight = RugbyTimerRenderer.getFontHeightSafe(dc, fonts.hintFont, height * 0.04);
        var hintLineGap = hintLineHeight + (height * 0.012);
        var hintHeight = 0;
        if (hintLines > 0) {
            hintHeight = hintLineHeight;
            if (hintLines > 1) {
                hintHeight = hintHeight + ((hintLines - 1) * hintLineGap);
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
    static function getCircleSafeBounds(width, height, rowY, padding) {
        var radius = (width < height ? width : height) / 2.0;
        var centerX = width / 2.0;
        var centerY = height / 2.0;
        var dy = rowY - centerY;
        var chordSquared = (radius * radius) - (dy * dy);
        if (chordSquared < 0) { chordSquared = 0; }
        var halfChord = Math.sqrt(chordSquared);
        return RugbyHorizontalBounds.create(centerX - halfChord + padding, centerX + halfChord - padding);
    }

    static function estimateLabelWidth(text, compact) {
        if (text == null) {
            return 0;
        }
        var perChar = compact == true ? 7 : 8;
        return (text.length() * perChar) + 4;
    }

    static function canFitScoreLabel(text, centerX, minX, maxX, compact) {
        var estimatedWidth = RugbyTimerRenderer.estimateLabelWidth(text, compact);
        var halfWidth = estimatedWidth / 2.0;
        return (centerX - halfWidth) >= minX && (centerX + halfWidth) <= maxX;
    }

    static function renderScoreLabels(dc, model, width, height, scoreY) {
        var activeLabelMode = RugbyTeamIdentitySupport.getDefaultLabelMode();
        if (model != null && model.teamLabelMode != null) {
            activeLabelMode = RugbyTeamIdentitySupport.normalizeLabelMode(model.teamLabelMode);
        }
        if (activeLabelMode == TEAM_LABEL_MODE_HOME_AWAY) {
            return false;
        }

        var labelY = scoreY - (height * 0.03);
        var homeX = width / 4;
        var awayX = 3 * width / 4;
        var homeLabel = RugbyTeamIdentitySupport.getScoreBandLabel(activeLabelMode, true, width <= 260);
        var awayLabel = RugbyTeamIdentitySupport.getScoreBandLabel(activeLabelMode, false, width <= 260);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(homeX, labelY, Graphics.FONT_XTINY, homeLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(awayX, labelY, Graphics.FONT_XTINY, awayLabel, Graphics.TEXT_JUSTIFY_CENTER);
        return true;
    }

    static function renderScores(dc, model, width, height, scoreFont, scoreY) {
        RugbyTimerRenderer.renderScoreLabels(dc, model, width, height, scoreY);
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
    static function renderGameTimer(dc, model, width, timerFont, gameTimerY, renderNow) {
        var elapsedSeconds = RugbyTimeMath.snapshotForwardClock(
            model.elapsedTime,
            model.lastUpdate,
            renderNow,
            model.gameState != STATE_IDLE && model.gameState != STATE_ENDED
        );
        var gameStr = RugbyTimerTiming.formatTime(elapsedSeconds);
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
    static function renderHalfAndTries(dc, model, width, height, halfFont, triesFont, halfY, triesY, labelsDrawn) {
        var halfStr = "Half " + model.halfNumber.toString();
        dc.drawText(width / 2, halfY, halfFont, halfStr, Graphics.TEXT_JUSTIFY_CENTER);
        var hideTries = (width <= 220) || (labelsDrawn == true && width <= 240);
        if (hideTries) {
            return;
        }
        var halfHeight = RugbyTimerRenderer.getFontHeightSafe(dc, halfFont, height * 0.045);
        var rowGap = height * 0.012;
        var measuredTriesY = halfY + halfHeight + rowGap;
        if (measuredTriesY > triesY) {
            triesY = measuredTriesY;
        }
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

    static function getCardRemaining(entry, timerNow) {
        var remaining = entry.remaining;
        if (!RugbyTimeMath.isNumeric(remaining)) {
            remaining = RugbyTimerCards.getEntryRemaining(entry, timerNow);
        }
        return remaining;
    }

    static function renderTimedCardEntries(dc, model, entries, timerNow, x, cardsY, state, style) {
        var count = state.visibleCount;
        var line = state.lineIndex;
        if (!(entries instanceof Lang.Array)) {
            return state;
        }
        var cardEntries = entries as Lang.Array;
        for (var i = 0; i < cardEntries.size(); i = i + 1) {
            if (count >= style.limit) {
                break;
            }
            var entry = CardEntry.fromDict(cardEntries[i]);
            if (entry == null) {
                continue;
            }
            var remaining = RugbyTimerRenderer.getCardRemaining(entry, timerNow);
            var label = entry.label;
            if (label == null) {
                label = style.labelPrefix + (i + 1).toString();
            }
            dc.setColor(style.color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                x,
                cardsY + line * style.lineStep,
                style.font,
                label + ": " + model.formatShortTime(RugbyTimerTiming.getDisplayCountdownSeconds(remaining)),
                Graphics.TEXT_JUSTIFY_CENTER
            );
            count += 1;
            line += 1;
        }
        return RugbyCardRenderState.create(count, line);
    }

    static function renderPermanentRed(dc, x, cardsY, lineStep, lineIndex, font, labelCounter) {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        var label = labelCounter > 0 ? "R" + labelCounter.toString() + ": PERM" : "R: PERM";
        dc.drawText(x, cardsY + lineIndex * lineStep, font, label, Graphics.TEXT_JUSTIFY_CENTER);
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
    static function renderCardTimers(dc, model, width, cardsY, height, renderNow) {
        Profiler.start("renderCardTimers");
        // Only render the first two active sanctions per team so the primary layout stays tidy while
        // extra yellow/red timers continue counting in the background.
        if (model.yellowHomeTimes == null) { model.yellowHomeTimes = []; }
        if (model.yellowAwayTimes == null) { model.yellowAwayTimes = []; }
        var timerNow = RugbyTimeMath.snapshotForwardClock(
            model.suspensionTime,
            model.lastUpdate,
            renderNow,
            RugbyTimerTiming.isSuspensionClockRunning(model.gameState)
        );
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
            var homeX = width / 4;
            var awayX = (3 * width) / 4;
            var cardFont = width <= 260 ? Graphics.FONT_XTINY : Graphics.FONT_SMALL;
            var cardFontRed = cardFont;
            var maxFontHeight = RugbyTimerRenderer.getFontHeightSafe(dc, cardFont, height * 0.04);
            lineStep = maxFontHeight + (height * 0.010);
            var yellowStyle = RugbyCardRenderStyle.create(2, Graphics.COLOR_YELLOW, "Y", cardFont, lineStep);
            var redStyle = RugbyCardRenderStyle.create(2, Graphics.COLOR_RED, "R", cardFontRed, lineStep);
            var homeState = RugbyTimerRenderer.renderTimedCardEntries(
                dc,
                model,
                model.yellowHomeTimes,
                timerNow,
                homeX,
                cardsY,
                RugbyCardRenderState.create(0, 0),
                yellowStyle
            );
            var awayState = RugbyTimerRenderer.renderTimedCardEntries(
                dc,
                model,
                model.yellowAwayTimes,
                timerNow,
                awayX,
                cardsY,
                RugbyCardRenderState.create(0, 0),
                yellowStyle
            );
            if (model.redHomePermanent && homeState.visibleCount < 2) {
                RugbyTimerRenderer.renderPermanentRed(dc, homeX, cardsY, lineStep, homeState.lineIndex, cardFontRed, model.redHomeLabelCounter);
                homeState = RugbyCardRenderState.create(homeState.visibleCount + 1, homeState.lineIndex + 1);
            } else {
                homeState = RugbyTimerRenderer.renderTimedCardEntries(
                    dc,
                    model,
                    model.redHomeTimes,
                    timerNow,
                    homeX,
                    cardsY,
                    homeState,
                    redStyle
                );
            }
            if (model.redAwayPermanent && awayState.visibleCount < 2) {
                RugbyTimerRenderer.renderPermanentRed(dc, awayX, cardsY, lineStep, awayState.lineIndex, cardFontRed, model.redAwayLabelCounter);
                awayState = RugbyCardRenderState.create(awayState.visibleCount + 1, awayState.lineIndex + 1);
            } else {
                awayState = RugbyTimerRenderer.renderTimedCardEntries(
                    dc,
                    model,
                    model.redAwayTimes,
                    timerNow,
                    awayX,
                    cardsY,
                    awayState,
                    redStyle
                );
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        Profiler.stop("renderCardTimers");
        return RugbyRenderedCardInfo.create(maxCardRows, lineStep, cardsY);
    }

    /**
     * Renders the countdown timer.
     * @param dc The device context
     * @param model The game model
     * @param width The width of the screen
     * @param countdownFont The font to use for the countdown timer
     * @param countdownY The Y position of the countdown timer
     */
    static function getMainCountdownSeconds(model, renderNow) {
        if (model.gameState == STATE_IDLE) {
            // Idle mode is configuration-only, so always render from the
            // configured half duration instead of any live countdown field.
            return RugbyTimeMath.normalizeSeconds(model.halfDuration);
        }
        if (model.gameState == STATE_HALFTIME) {
            if (model.countdownSeconds > 0) {
                return RugbyTimeMath.snapshotReverseClock(
                    model.countdownSeconds,
                    model.lastUpdate,
                    renderNow,
                    true
                );
            }
            return RugbyTimeMath.normalizeSeconds(model.halfDuration);
        }
        return RugbyTimeMath.getCountdownRemaining(
            model.countdownTimer,
            RugbyTimeMath.snapshotForwardClock(
                model.gameTime,
                model.lastUpdate,
                renderNow,
                RugbyTimerTiming.isClockRunning(model.gameState)
            )
        );
    }

    static function renderCountdown(dc, model, width, countdownFont, countdownY, renderNow) {
        Profiler.start("renderCountdown");
        // Draw the large, white countdown digits centered so refs can still read the main clock even when the overlay
        // kicks in.
        var remainingSeconds = RugbyTimerRenderer.getMainCountdownSeconds(model, renderNow);
        var displaySeconds = RugbyTimerTiming.getDisplayCountdownSeconds(remainingSeconds);
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
    static function renderStateText(dc, model, width, stateFont, stateY, height, renderNow) {
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
            var convSeconds = RugbyTimerTiming.getDisplayCountdownSeconds(
                RugbyTimeMath.snapshotReverseClock(model.countdownSeconds, model.lastUpdate, renderNow, true)
            );
            var countdownStr = (convSeconds as Lang.Number).toLong().toString();
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, countdownStr + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_PENALTY) {
            dc.drawText(width / 2, stateY, stateFont, "PENALTY KICK", Graphics.TEXT_JUSTIFY_CENTER);
            var penSeconds = RugbyTimerTiming.getDisplayCountdownSeconds(
                RugbyTimeMath.snapshotReverseClock(model.countdownSeconds, model.lastUpdate, renderNow, true)
            );
            var countdownStr = (penSeconds as Lang.Number).toLong().toString();
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, countdownStr + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_HALFTIME) {
            var halftimeText = model.countdownSeconds > 0 ? "HALF TIME" : "HALF 2 READY";
            dc.drawText(width / 2, stateY, stateFont, halftimeText, Graphics.TEXT_JUSTIFY_CENTER);
        } else if (model.gameState == STATE_ENDED) {
            dc.drawText(width / 2, stateY, stateFont, "GAME ENDED", Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

}
