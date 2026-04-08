using Toybox.Test;
using Toybox.Lang;

/*
Headless renderer layout regression tests.

Purpose: keep the main countdown anchor stable across state changes and verify
that visible card rows still push the countdown lower when space allows.
*/

class TestLayoutDeviceContext {
    var countdownHeight;
    var stateHeight;
    var hintHeight;

    function initialize(countdownHeightValue, stateHeightValue, hintHeightValue) {
        countdownHeight = countdownHeightValue;
        stateHeight = stateHeightValue;
        hintHeight = hintHeightValue;
    }

    function getFontHeight(font) {
        if (font == "countdown") { return countdownHeight; }
        if (font == "state") { return stateHeight; }
        if (font == "hint") { return hintHeight; }
        return 10;
    }
}

class TestLayoutParts {
    var fonts;
    var layout;
}

function buildTestLayout(dc, width, height) {
    var fonts = RugbyTimerRenderer.chooseFonts(width);
    var family = width == height ? "compact_round" : "rect";
    if (width == height && width > 240) {
        family = "large_round";
    }
    var guide = RugbyLayoutSupport.resolveGuide(null, family);
    var parts = new TestLayoutParts();
    parts.fonts = fonts;
    parts.layout = RugbyTimerRenderer.calculateLayout(dc, width, height, fonts, guide);
    return parts;
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
    var width = 240;
    var dc = new TestLayoutDeviceContext(120, 16, 12);
    var parts = buildTestLayout(dc, width, height);
    var fonts = parts.fonts;
    var layout = parts.layout;
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
    var width = 240;
    var dc = new TestLayoutDeviceContext(120, 16, 12);
    var parts = buildTestLayout(dc, width, height);
    var fonts = parts.fonts;
    var layout = parts.layout;
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
    var width = 260;
    var dc = new TestLayoutDeviceContext(72, 16, 12);
    var parts = buildTestLayout(dc, width, height);
    var fonts = parts.fonts;
    var layout = parts.layout;
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
    var width = 260;
    var dc = new TestLayoutDeviceContext(72, 16, 12);
    var parts = buildTestLayout(dc, width, height);
    var fonts = parts.fonts;
    var layout = parts.layout;
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
function test_calculateLayout_keeps_header_inside_safe_band(logger as Test.Logger) as Lang.Boolean {
    var dc = new TestLayoutDeviceContext(72, 16, 12);
    var parts = buildTestLayout(dc, 240, 240);
    var layout = parts.layout;

    if (!(layout.gameTimerY >= layout.safeTop)) {
        logger.error("game timer moved above safe top");
        return false;
    }
    if (!(layout.teamLabelY > layout.gameTimerY && layout.scoreY > layout.teamLabelY)) {
        logger.error("header rows are out of order");
        return false;
    }
    if (!(layout.headerBottomY < layout.cardsY && layout.homeScoreX > layout.safeLeft && layout.awayScoreX < layout.safeRight)) {
        logger.error("header or score anchors escaped safe content");
        return false;
    }
    if (!(layout.halfY > layout.scoreY + 10 && layout.triesY > layout.halfY)) {
        logger.error("center metadata drifted into the score band");
        return false;
    }

    return true;
}

(:test)
function test_mainContentLayout_keeps_idle_countdown_inside_safe_bottom(logger as Test.Logger) as Lang.Boolean {
    var height = 240;
    var width = 240;
    var dc = new TestLayoutDeviceContext(72, 16, 12);
    var parts = buildTestLayout(dc, width, height);
    var fonts = parts.fonts;
    var layout = parts.layout;
    var main = RugbyTimerRenderer.calculateMainContentLayout(dc, new TestLayoutModel(STATE_IDLE), fonts, layout, RugbyRenderedCardInfo.create(0, 18, layout.cardsY), height, false);
    var countdownBottom = main.countdownY + dc.getFontHeight("countdown");
    var safeBottomLimit = layout.safeBottom - (height * 0.02);

    if (countdownBottom > safeBottomLimit) {
        logger.error("idle countdown overflowed safe bottom");
        return false;
    }

    return true;
}
