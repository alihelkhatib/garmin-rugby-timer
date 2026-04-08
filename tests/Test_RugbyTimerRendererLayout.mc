using Toybox.Test;
using Toybox.Lang;
using Toybox.Graphics;

/*
Headless renderer layout regression tests.

Purpose: keep the main countdown anchor stable across state changes and verify
that visible card rows still push the countdown lower when space allows.
*/

class TestLayoutDeviceContext {
    var timerHeight;
    var labelHeight;
    var scoreHeight;
    var halfRowHeight;
    var triesRowHeight;
    var countdownHeight;
    var stateHeight;
    var hintHeight;

    function initialize(countdownHeightValue, stateHeightValue, hintHeightValue) {
        timerHeight = 12;
        labelHeight = 12;
        scoreHeight = 42;
        halfRowHeight = 12;
        triesRowHeight = 12;
        countdownHeight = countdownHeightValue;
        stateHeight = stateHeightValue;
        hintHeight = hintHeightValue;
    }

    function getFontHeight(font) {
        if (font == "timer") { return timerHeight; }
        if (font == "score") { return scoreHeight; }
        if (font == "half") { return halfRowHeight; }
        if (font == "tries") { return triesRowHeight; }
        if (font == "countdown") { return countdownHeight; }
        if (font == "state") { return stateHeight; }
        if (font == "hint") { return hintHeight; }
        if (font == Graphics.FONT_XTINY || font == Graphics.FONT_SMALL || font == Graphics.FONT_TINY) { return labelHeight; }
        return 10;
    }
}

class TestLayoutModel {
    var gameState;

    function initialize(stateValue) {
        gameState = stateValue;
    }
}

(:test)
function test_mainContentLayout_keeps_countdown_stable_between_idle_and_playing(logger as Test.Logger) as Lang.Boolean {
    var height = 240;
    var dc = new TestLayoutDeviceContext(120, 16, 12);
    var fonts = RugbyRenderFonts.create("score", "tries", "half", "timer", "countdown", "state", "hint");
    var layout = RugbyTimerRenderer.calculateLayout(dc, fonts, 240, height);
    var cardInfo = RugbyRenderedCardInfo.create(0, 18, layout.cardsY);

    var idleLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, new TestLayoutModel(STATE_IDLE), fonts, layout, cardInfo, height, false);
    var playingLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, new TestLayoutModel(STATE_PLAYING), fonts, layout, cardInfo, height, false);

    if (idleLayout.countdownY != playingLayout.countdownY) {
        logger.error("countdownY drifted from " + idleLayout.countdownY.format("%.2f") + " to " + playingLayout.countdownY.format("%.2f"));
        return false;
    }

    return true;
}

(:test)
function test_mainContentLayout_keeps_countdown_stable_between_playing_and_paused(logger as Test.Logger) as Lang.Boolean {
    var height = 240;
    var dc = new TestLayoutDeviceContext(120, 16, 12);
    var fonts = RugbyRenderFonts.create("score", "tries", "half", "timer", "countdown", "state", "hint");
    var layout = RugbyTimerRenderer.calculateLayout(dc, fonts, 240, height);
    var cardInfo = RugbyRenderedCardInfo.create(0, 18, layout.cardsY);

    var playingLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, new TestLayoutModel(STATE_PLAYING), fonts, layout, cardInfo, height, false);
    var pausedLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, new TestLayoutModel(STATE_PAUSED), fonts, layout, cardInfo, height, false);

    if (playingLayout.countdownY != pausedLayout.countdownY) {
        logger.error("countdownY drifted from " + playingLayout.countdownY.format("%.2f") + " to " + pausedLayout.countdownY.format("%.2f"));
        return false;
    }

    return true;
}

(:test)
function test_mainContentLayout_keeps_countdown_stable_between_playing_and_paused_with_cards(logger as Test.Logger) as Lang.Boolean {
    var height = 260;
    var dc = new TestLayoutDeviceContext(72, 16, 12);
    var fonts = RugbyRenderFonts.create("score", "tries", "half", "timer", "countdown", "state", "hint");
    var layout = RugbyTimerRenderer.calculateLayout(dc, fonts, 260, height);
    var cardInfo = RugbyRenderedCardInfo.create(2, 18, layout.cardsY);

    var playingLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, new TestLayoutModel(STATE_PLAYING), fonts, layout, cardInfo, height, false);
    var pausedLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, new TestLayoutModel(STATE_PAUSED), fonts, layout, cardInfo, height, false);

    if (playingLayout.countdownY != pausedLayout.countdownY) {
        logger.error("countdownY with cards drifted from " + playingLayout.countdownY.format("%.2f") + " to " + pausedLayout.countdownY.format("%.2f"));
        return false;
    }

    return true;
}

(:test)
function test_mainContentLayout_moves_down_for_visible_card_rows(logger as Test.Logger) as Lang.Boolean {
    var height = 260;
    var dc = new TestLayoutDeviceContext(72, 16, 12);
    var fonts = RugbyRenderFonts.create("score", "tries", "half", "timer", "countdown", "state", "hint");
    var layout = RugbyTimerRenderer.calculateLayout(dc, fonts, 260, height);
    var playingModel = new TestLayoutModel(STATE_PLAYING);

    var baseLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, playingModel, fonts, layout, RugbyRenderedCardInfo.create(0, 18, layout.cardsY), height, false);
    var stackedLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, playingModel, fonts, layout, RugbyRenderedCardInfo.create(2, 18, layout.cardsY), height, false);

    if (!(stackedLayout.countdownY > baseLayout.countdownY)) {
        logger.error("card rows did not lower countdownY");
        return false;
    }

    return true;
}

(:test)
function test_calculateLayout_keeps_team_labels_inside_safe_header_band(logger as Test.Logger) as Lang.Boolean {
    var height = 240;
    var width = 240;
    var dc = new TestLayoutDeviceContext(120, 16, 12);
    var fonts = RugbyRenderFonts.create("score", "tries", "half", "timer", "countdown", "state", "hint");
    var layout = RugbyTimerRenderer.calculateLayout(dc, fonts, width, height);

    if (!(layout.teamLabelY > layout.gameTimerY)) {
        logger.error("teamLabelY should be below gameTimerY");
        return false;
    }
    if (!(layout.scoreY > layout.teamLabelY)) {
        logger.error("scoreY should be below teamLabelY");
        return false;
    }
    return layout.teamLabelY > 0 && layout.cardsY > layout.triesY;
}
