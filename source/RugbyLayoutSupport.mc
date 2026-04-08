using Rez.Layouts;

class RugbyLayoutSupport {
    static function applyMainLayout(view, dc, width, height) {
        var family = RugbyLayoutSupport.getFamily(width, height);
        if (family == "rect") {
            view.setLayout(Rez.Layouts.MainLayoutRect(dc));
            return family;
        }
        if (family == "compact_round") {
            view.setLayout(Rez.Layouts.MainLayoutCompactRound(dc));
            return family;
        }
        view.setLayout(Rez.Layouts.MainLayoutLargeRound(dc));
        return family;
    }

    static function resolveGuide(view, family) {
        var drawable = null;
        if (view != null) {
            try {
                drawable = view.findDrawableById("LayoutGuide") as RugbyLayoutGuideDrawable;
            } catch (ex) {
                drawable = null;
            }
        }
        if (drawable != null && drawable.guide != null) {
            return drawable.guide;
        }
        return RugbyLayoutSupport.createFallbackGuideByFamily(family);
    }

    static function createFallbackGuide(width, height) {
        if (RugbyLayoutSupport.isRectangular(width, height)) {
            return RugbyLayoutSupport.createFallbackGuideByFamily("rect");
        }
        if (width <= 240) {
            return RugbyLayoutSupport.createFallbackGuideByFamily("compact_round");
        }
        return RugbyLayoutSupport.createFallbackGuideByFamily("large_round");
    }

    static function createFallbackGuideByFamily(family) {
        var guide = RugbyLayoutGuide.create();
        if (family == "rect") {
            guide.family = "rect";
            guide.safeTopPct = 0.06;
            guide.safeBottomPct = 0.06;
            guide.safeSidePct = 0.05;
            guide.headerGapPct = 0.010;
            guide.cardsGapPct = 0.025;
            guide.stateGapPct = 0.018;
            guide.hintGapPct = 0.014;
            guide.iconInsetPct = 0.040;
            guide.lowerBandGapPct = 0.16;
            guide.cardInsetPct = 0.24;
            return guide;
        }
        if (family == "compact_round") {
            guide.family = "compact_round";
            guide.safeTopPct = 0.09;
            guide.safeBottomPct = 0.08;
            guide.safeSidePct = 0.10;
            guide.headerGapPct = 0.012;
            guide.cardsGapPct = 0.028;
            guide.stateGapPct = 0.020;
            guide.hintGapPct = 0.015;
            guide.iconInsetPct = 0.050;
            guide.lowerBandGapPct = 0.18;
            guide.cardInsetPct = 0.23;
            return guide;
        }
        guide.family = "large_round";
        guide.safeTopPct = 0.10;
        guide.safeBottomPct = 0.09;
        guide.safeSidePct = 0.10;
        guide.headerGapPct = 0.010;
        guide.cardsGapPct = 0.025;
        guide.stateGapPct = 0.018;
        guide.hintGapPct = 0.014;
        guide.iconInsetPct = 0.045;
        guide.lowerBandGapPct = 0.17;
        guide.cardInsetPct = 0.24;
        return guide;
    }

    static function isRectangular(width, height) {
        return width != height;
    }

    static function getFamily(width, height) {
        if (RugbyLayoutSupport.isRectangular(width, height)) {
            return "rect";
        }
        if (width <= 240) {
            return "compact_round";
        }
        return "large_round";
    }
}
