/**
 * Typed renderer support objects used to keep layout/font data off raw
 * dictionaries in the render path.
 *
 * Purpose: define the small render-only data carriers shared between the
 * renderer, timing, cards, and view layers.
 */
class RugbyRenderFonts {
    var scoreFont;
    var triesFont;
    var halfFont;
    var timerFont;
    var countdownFont;
    var stateFont;
    var hintFont;

    static function create(scoreFont, triesFont, halfFont, timerFont, countdownFont, stateFont, hintFont) {
        var fonts = new RugbyRenderFonts();
        fonts.scoreFont = scoreFont;
        fonts.triesFont = triesFont;
        fonts.halfFont = halfFont;
        fonts.timerFont = timerFont;
        fonts.countdownFont = countdownFont;
        fonts.stateFont = stateFont;
        fonts.hintFont = hintFont;
        return fonts;
    }
}

class RugbyRenderLayoutCacheEntry {
    var key;
    var layout;

    static function create(key, layout) {
        var entry = new RugbyRenderLayoutCacheEntry();
        entry.key = key;
        entry.layout = layout;
        return entry;
    }
}

class RugbyMainContentLayoutCacheEntry {
    var key;
    var layout;

    static function create(key, layout) {
        var entry = new RugbyMainContentLayoutCacheEntry();
        entry.key = key;
        entry.layout = layout;
        return entry;
    }
}

class RugbyRenderLayout {
    var family;
    var compactDetailMode;
    var safeLeft;
    var safeRight;
    var safeTop;
    var safeBottom;
    var contentWidth;
    var contentHeight;
    var centerX;
    var homeScoreX;
    var awayScoreX;
    var homeTriesX;
    var awayTriesX;
    var homeCardAnchorX;
    var awayCardAnchorX;
    var scoreY;
    var teamLabelY;
    var halfY;
    var gameTimerY;
    var triesY;
    var headerBottomY;
    var cardsY;
    var stateBaseY;
    var hintBaseY;
    var lowerBandTopY;
    var iconY;
    var showIcons;
    var showElapsedTimer;
    var showHalf;
    var showTries;

    static function create() {
        return new RugbyRenderLayout();
    }
}

class RugbyLayoutGuide {
    var family;
    var safeTopPct;
    var safeBottomPct;
    var safeSidePct;
    var headerGapPct;
    var cardsGapPct;
    var stateGapPct;
    var hintGapPct;
    var iconInsetPct;
    var lowerBandGapPct;
    var cardInsetPct;

    static function create() {
        return new RugbyLayoutGuide();
    }
}

class RugbyRenderedCardInfo {
    var rows;
    var lineStep;
    var cardsY;

    static function create(rows, lineStep, cardsY) {
        var info = new RugbyRenderedCardInfo();
        info.rows = rows;
        info.lineStep = lineStep;
        info.cardsY = cardsY;
        return info;
    }
}

class RugbyMainContentLayout {
    var countdownY;
    var stateY;
    var hintY;
    var hintLineGap;

    static function create(countdownY, stateY, hintY, hintLineGap) {
        var layout = new RugbyMainContentLayout();
        layout.countdownY = countdownY;
        layout.stateY = stateY;
        layout.hintY = hintY;
        layout.hintLineGap = hintLineGap;
        return layout;
    }
}

class RugbyTimerUpdateResult {
    var timers;
    var expired;

    static function create(timers, expired) {
        var result = new RugbyTimerUpdateResult();
        result.timers = timers;
        result.expired = expired == true;
        return result;
    }
}
