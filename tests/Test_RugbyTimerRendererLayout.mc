using Toybox.Test;
using Toybox.Lang;
using Toybox.Graphics;

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

function buildTestLayout(dc, width, height, model) {
    var fonts = RugbyTimerRenderer.chooseFonts(width);
    var family = width == height ? "compact_round" : "rect";
    if (width == height && width > 240) {
        family = "large_round";
    }
    var guide = RugbyLayoutSupport.resolveGuide(null, family);
    var parts = new TestLayoutParts();
    parts.fonts = fonts;
    parts.layout = RugbyTimerRenderer.calculateLayout(dc, width, height, fonts, guide, model);
    return parts;
}

class TestLayoutModel {
    var gameState;
    var yellowHomeTimes;
    var yellowAwayTimes;
    var redHomeTimes;
    var redAwayTimes;
    var redHomePermanent;
    var redAwayPermanent;
    var suspensionTime;
    var halfNumber;
    var homeTries;
    var awayTries;
    var elapsedTime;
    var countdownRemaining;

    function initialize(stateValue) {
        gameState = stateValue;
        yellowHomeTimes = [];
        yellowAwayTimes = [];
        redHomeTimes = [];
        redAwayTimes = [];
        redHomePermanent = false;
        redAwayPermanent = false;
        suspensionTime = 0;
        halfNumber = 1;
        homeTries = 0;
        awayTries = 0;
        elapsedTime = 0;
        countdownRemaining = 2400;
    }
}

(:test)
function test_mainContentLayout_keeps_countdown_stable_between_idle_and_playing(logger as Test.Logger) as Lang.Boolean {
    var height = 240;
    var width = 240;
    var dc = new TestLayoutDeviceContext(120, 16, 12);
    var model = new TestLayoutModel(STATE_IDLE);
    var parts = buildTestLayout(dc, width, height, model);
    var fonts = parts.fonts;
    var layout = parts.layout;
    var cardInfo = RugbyRenderedCardInfo.create(0, 18, layout.cardsY);

    var idleLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, model, fonts, layout, cardInfo, height, false);
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
    var model = new TestLayoutModel(STATE_PLAYING);
    var parts = buildTestLayout(dc, width, height, model);
    var fonts = parts.fonts;
    var layout = parts.layout;
    var cardInfo = RugbyRenderedCardInfo.create(0, 18, layout.cardsY);

    var playingLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, model, fonts, layout, cardInfo, height, false);
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
    var model = new TestLayoutModel(STATE_PLAYING);
    model.yellowHomeTimes = [{ "remaining" => 300, "label" => "Y1", "cardId" => 1 }];
    var parts = buildTestLayout(dc, width, height, model);
    var fonts = parts.fonts;
    var layout = parts.layout;
    var cardInfo = RugbyRenderedCardInfo.create(2, 18, layout.cardsY);

    var playingLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, model, fonts, layout, cardInfo, height, false);
    var pausedModel = new TestLayoutModel(STATE_PAUSED);
    pausedModel.yellowHomeTimes = model.yellowHomeTimes;
    var pausedLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, pausedModel, fonts, layout, cardInfo, height, false);

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
    var model = new TestLayoutModel(STATE_PLAYING);
    var parts = buildTestLayout(dc, width, height, model);
    var fonts = parts.fonts;
    var layout = parts.layout;
    var playingModel = model;

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
    var model = new TestLayoutModel(STATE_IDLE);
    var parts = buildTestLayout(dc, 240, 240, model);
    var layout = parts.layout;

    if (!(layout.gameTimerY >= layout.safeTop)) {
        logger.error("game timer moved above safe top");
        return false;
    }
    if (!(layout.scoreY > layout.teamLabelY)) {
        logger.error("header rows are out of order");
        return false;
    }
    if (!(layout.headerBottomY < layout.cardsY && layout.homeScoreX > layout.safeLeft && layout.awayScoreX < layout.safeRight)) {
        logger.error("header or score anchors escaped safe content");
        return false;
    }
    if (layout.showHalf && !(layout.halfY > layout.scoreY + 10)) {
        logger.error("half row drifted into the score band");
        return false;
    }
    if (!(layout.homeTriesX < layout.homeScoreX && layout.awayTriesX > layout.awayScoreX)) {
        logger.error("tries were not anchored beside their score columns");
        return false;
    }
    if (layout.showTries && !(layout.triesY > layout.scoreY && layout.triesY < layout.headerBottomY)) {
        logger.error("tries did not stay in the score-adjacent band");
        return false;
    }

    return true;
}

(:test)
function test_compact_round_fonts_reduce_hint_and_label_emphasis(logger as Test.Logger) as Lang.Boolean {
    var fonts = RugbyTimerRenderer.chooseFonts(240);
    if (fonts.hintFont != Graphics.FONT_XTINY) {
        logger.error("compact-round idle hints did not shrink");
        return false;
    }
    if (RugbyTimerRenderer.chooseTeamLabelFont(240) != Graphics.FONT_SYSTEM_TINY) {
        logger.error("compact-round team labels did not shrink");
        return false;
    }
    return true;
}

(:test)
function test_mainContentLayout_keeps_idle_countdown_inside_safe_bottom(logger as Test.Logger) as Lang.Boolean {
    var height = 240;
    var width = 240;
    var dc = new TestLayoutDeviceContext(72, 16, 12);
    var model = new TestLayoutModel(STATE_IDLE);
    var parts = buildTestLayout(dc, width, height, model);
    var fonts = parts.fonts;
    var layout = parts.layout;
    var main = RugbyTimerRenderer.calculateMainContentLayout(dc, model, fonts, layout, RugbyRenderedCardInfo.create(0, 18, layout.cardsY), height, false);
    var countdownBottom = main.countdownY + dc.getFontHeight("countdown");
    var safeBottomLimit = layout.safeBottom - (height * 0.02);

    if (countdownBottom > safeBottomLimit) {
        logger.error("idle countdown overflowed safe bottom");
        return false;
    }

    return true;
}

(:test)
function test_compactDetailMode_recovers_metadata_in_priority_order(logger as Test.Logger) as Lang.Boolean {
    var modeCritical = RugbyTimerRenderer.chooseCompactDetailMode(new TestLayoutModel(STATE_PLAYING), 192, 170);
    var modeElapsed = RugbyTimerRenderer.chooseCompactDetailMode(new TestLayoutModel(STATE_PLAYING), 192, 190);
    var modeHalf = RugbyTimerRenderer.chooseCompactDetailMode(new TestLayoutModel(STATE_PLAYING), 192, 210);
    var modeFull = RugbyTimerRenderer.chooseCompactDetailMode(new TestLayoutModel(STATE_PLAYING), 210, 222);

    if (modeCritical != "critical-only") {
        logger.error("expected critical-only fallback");
        return false;
    }
    if (modeElapsed != "critical-plus-elapsed") {
        logger.error("elapsed did not return first");
        return false;
    }
    if (modeHalf != "critical-plus-elapsed-half") {
        logger.error("half did not return before tries");
        return false;
    }
    if (modeFull != "full-compact") {
        logger.error("tries did not return last");
        return false;
    }
    return true;
}

(:test)
function test_calculateLayout_compact_round_uses_critical_only_for_timed_cards(logger as Test.Logger) as Lang.Boolean {
    var dc = new TestLayoutDeviceContext(72, 16, 12);
    var model = new TestLayoutModel(STATE_PLAYING);
    model.yellowHomeTimes = [{ "remaining" => 300, "label" => "Y1", "cardId" => 1 }];
    var parts = buildTestLayout(dc, 240, 240, model);
    var layout = parts.layout;

    if (layout.compactDetailMode != "critical-only") {
        logger.error("timed cards did not force critical-only mode");
        return false;
    }
    if (layout.showElapsedTimer || layout.showHalf || layout.showTries) {
        logger.error("optional metadata stayed visible in critical-only mode");
        return false;
    }
    return true;
}

(:test)
function test_calculateLayout_compact_round_no_cards_returns_elapsed_before_half(logger as Test.Logger) as Lang.Boolean {
    var dc = new TestLayoutDeviceContext(72, 16, 12);
    var model = new TestLayoutModel(STATE_IDLE);
    var parts = buildTestLayout(dc, 240, 240, model);
    var layout = parts.layout;

    if (layout.compactDetailMode != "critical-plus-elapsed") {
        logger.error("compact round no-card layout did not settle on elapsed-first mode");
        return false;
    }
    if (!layout.showElapsedTimer || layout.showHalf || layout.showTries) {
        logger.error("compact round no-card layout restored metadata out of order");
        return false;
    }
    return true;
}

(:test)
function test_compactRound_countdown_stays_stable_between_playing_and_paused_with_timed_cards(logger as Test.Logger) as Lang.Boolean {
    var height = 240;
    var width = 240;
    var dc = new TestLayoutDeviceContext(72, 16, 12);
    var playingModel = new TestLayoutModel(STATE_PLAYING);
    playingModel.yellowHomeTimes = [{ "remaining" => 300, "label" => "Y1", "cardId" => 1 }];
    var pausedModel = new TestLayoutModel(STATE_PAUSED);
    pausedModel.yellowHomeTimes = playingModel.yellowHomeTimes;

    var parts = buildTestLayout(dc, width, height, playingModel);
    var fonts = parts.fonts;
    var layout = parts.layout;
    var cardInfo = RugbyRenderedCardInfo.create(1, 18, layout.cardsY);
    var playingLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, playingModel, fonts, layout, cardInfo, height, false);
    var pausedLayout = RugbyTimerRenderer.calculateMainContentLayout(dc, pausedModel, fonts, layout, cardInfo, height, false);

    if (playingLayout.countdownY != pausedLayout.countdownY) {
        logger.error("compact-round timed-card countdown drifted between playing and paused");
        return false;
    }
    return true;
}

(:test)
function test_getUrgentCardEntry_picks_lowest_remaining_time(logger as Test.Logger) as Lang.Boolean {
    var urgent = RugbyTimerRenderer.getUrgentCardEntry([
        { "startTime" => 0, "duration" => 600, "remaining" => 540, "label" => "Y2", "cardId" => 2, "vibeTriggered" => false },
        { "startTime" => 0, "duration" => 600, "remaining" => 120, "label" => "Y1", "cardId" => 1, "vibeTriggered" => false }
    ], 0);

    if (urgent == null) {
        logger.error("urgent card entry was null");
        return false;
    }
    if (urgent.label != "Y1") {
        logger.error("urgent card selection ignored the lowest remaining time");
        return false;
    }

    return true;
}

(:test)
function test_getUrgentCardEntry_skips_expired_entries(logger as Test.Logger) as Lang.Boolean {
    var urgent = RugbyTimerRenderer.getUrgentCardEntry([
        { "startTime" => 0, "duration" => 600, "remaining" => 0, "label" => "Y2", "cardId" => 2, "vibeTriggered" => false },
        { "startTime" => 0, "duration" => 600, "remaining" => 90, "label" => "Y1", "cardId" => 1, "vibeTriggered" => false }
    ], 0);

    if (urgent == null || urgent.label != "Y1") {
        logger.error("expired entries still outranked live timed cards");
        return false;
    }

    return true;
}
