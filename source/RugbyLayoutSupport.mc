using Rez.Layouts;

class RugbyLayoutSupport {
    static function applyLayout(view, dc, width, height, useOverlayLayout) {
        var family = RugbyLayoutSupport.getFamily(width, height);
        var layoutId = RugbyLayoutSupport.getLayoutId(family, useOverlayLayout);
        if (layoutId == "OverlayLayoutRect") {
            view.setLayout(Rez.Layouts.OverlayLayoutRect(dc));
        } else if (layoutId == "OverlayLayoutCompactRound") {
            view.setLayout(Rez.Layouts.OverlayLayoutCompactRound(dc));
        } else if (layoutId == "OverlayLayoutLargeRound") {
            view.setLayout(Rez.Layouts.OverlayLayoutLargeRound(dc));
        } else if (layoutId == "MainLayoutRect") {
            view.setLayout(Rez.Layouts.MainLayoutRect(dc));
        } else if (layoutId == "MainLayoutCompactRound") {
            view.setLayout(Rez.Layouts.MainLayoutCompactRound(dc));
        } else {
            view.setLayout(Rez.Layouts.MainLayoutLargeRound(dc));
        }
        return layoutId;
    }

    static function getLayoutId(family, useOverlayLayout) {
        if (useOverlayLayout) {
            if (family == "rect") {
                return "OverlayLayoutRect";
            }
            if (family == "compact_round") {
                return "OverlayLayoutCompactRound";
            }
            return "OverlayLayoutLargeRound";
        }
        if (family == "rect") {
            return "MainLayoutRect";
        }
        if (family == "compact_round") {
            return "MainLayoutCompactRound";
        }
        return "MainLayoutLargeRound";
    }

    static function isOverlayLayout(layoutId) {
        return layoutId == "OverlayLayoutRect"
            || layoutId == "OverlayLayoutCompactRound"
            || layoutId == "OverlayLayoutLargeRound";
    }

    static function isCompactRound(family) {
        return family == "compact_round";
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
