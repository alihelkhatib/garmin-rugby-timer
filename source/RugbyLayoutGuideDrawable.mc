using Toybox.Lang;
using Toybox.WatchUi;

class RugbyLayoutGuideDrawable extends WatchUi.Drawable {
    var guide;

    function initialize(params) {
        Drawable.initialize(params);
        guide = RugbyLayoutGuide.create();
        guide.family = RugbyLayoutGuideDrawable.getStringParam(params, :family, "compact_round");
        guide.safeTopPct = RugbyLayoutGuideDrawable.getNumberParam(params, :safeTopPct, 0.12);
        guide.safeBottomPct = RugbyLayoutGuideDrawable.getNumberParam(params, :safeBottomPct, 0.10);
        guide.safeSidePct = RugbyLayoutGuideDrawable.getNumberParam(params, :safeSidePct, 0.12);
        guide.headerGapPct = RugbyLayoutGuideDrawable.getNumberParam(params, :headerGapPct, 0.012);
        guide.cardsGapPct = RugbyLayoutGuideDrawable.getNumberParam(params, :cardsGapPct, 0.028);
        guide.stateGapPct = RugbyLayoutGuideDrawable.getNumberParam(params, :stateGapPct, 0.020);
        guide.hintGapPct = RugbyLayoutGuideDrawable.getNumberParam(params, :hintGapPct, 0.015);
        guide.iconInsetPct = RugbyLayoutGuideDrawable.getNumberParam(params, :iconInsetPct, 0.050);
        guide.lowerBandGapPct = RugbyLayoutGuideDrawable.getNumberParam(params, :lowerBandGapPct, 0.16);
        guide.cardInsetPct = RugbyLayoutGuideDrawable.getNumberParam(params, :cardInsetPct, 0.23);
    }

    static function getStringParam(params, key, fallback) {
        if (params == null) {
            return fallback;
        }
        var value = params.get(key);
        if (value instanceof Lang.String) {
            return value;
        }
        return fallback;
    }

    static function getNumberParam(params, key, fallback) {
        if (params == null) {
            return fallback;
        }
        var value = params.get(key);
        if (value instanceof Lang.Number || value instanceof Lang.Float) {
            return value;
        }
        return fallback;
    }

    function draw(dc) {
        // This drawable only carries layout metadata from XML to the view.
    }

    static function createFallback(family) {
        return RugbyLayoutSupport.createFallbackGuideByFamily(family);
    }
}
