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
    var scoreY;
    var halfY;
    var gameTimerY;
    var triesY;
    var cardsY;
    var stateBaseY;
    var hintBaseY;
    var iconY;

    static function create(scoreY, halfY, gameTimerY, triesY, cardsY, stateBaseY, hintBaseY, iconY) {
        var layout = new RugbyRenderLayout();
        layout.scoreY = scoreY;
        layout.halfY = halfY;
        layout.gameTimerY = gameTimerY;
        layout.triesY = triesY;
        layout.cardsY = cardsY;
        layout.stateBaseY = stateBaseY;
        layout.hintBaseY = hintBaseY;
        layout.iconY = iconY;
        return layout;
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

class RugbyCardRenderState {
    var visibleCount;
    var lineIndex;

    static function create(visibleCount, lineIndex) {
        var state = new RugbyCardRenderState();
        state.visibleCount = visibleCount;
        state.lineIndex = lineIndex;
        return state;
    }
}

class RugbyCardRenderStyle {
    var limit;
    var color;
    var labelPrefix;
    var font;
    var lineStep;

    static function create(limit, color, labelPrefix, font, lineStep) {
        var style = new RugbyCardRenderStyle();
        style.limit = limit;
        style.color = color;
        style.labelPrefix = labelPrefix;
        style.font = font;
        style.lineStep = lineStep;
        return style;
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

class RugbyHorizontalBounds {
    var left;
    var right;

    static function create(left, right) {
        var bounds = new RugbyHorizontalBounds();
        bounds.left = left;
        bounds.right = right;
        return bounds;
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
