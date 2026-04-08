using Toybox.Test;
using Toybox.Lang;

/*
Unit tests for family and XML layout selection.

Purpose: keep the XML-first screen flow choosing the correct family and layout
without relying on the old fallback guide model.
*/

(:test)
function test_layoutSupport_getFamily_returns_compact_round_for_240_square(logger as Test.Logger) as Lang.Boolean {
    var family = RugbyLayoutSupport.getFamily(240, 240);
    if (family != "compact_round") {
        logger.error("expected compact_round, got " + family);
        return false;
    }
    return true;
}

(:test)
function test_layoutSupport_getFamily_returns_large_round_for_larger_square(logger as Test.Logger) as Lang.Boolean {
    var family = RugbyLayoutSupport.getFamily(260, 260);
    if (family != "large_round") {
        logger.error("expected large_round, got " + family);
        return false;
    }
    return true;
}

(:test)
function test_layoutSupport_getFamily_returns_rect_for_rectangular(logger as Test.Logger) as Lang.Boolean {
    var family = RugbyLayoutSupport.getFamily(205, 148);
    if (family != "rect") {
        logger.error("expected rect, got " + family);
        return false;
    }
    return true;
}

(:test)
function test_layoutSupport_getLayoutId_switches_between_main_and_overlay(logger as Test.Logger) as Lang.Boolean {
    if (RugbyLayoutSupport.getLayoutId("compact_round", false) != "MainLayoutCompactRound") {
        logger.error("compact main layout id mismatch");
        return false;
    }
    if (RugbyLayoutSupport.getLayoutId("large_round", true) != "OverlayLayoutLargeRound") {
        logger.error("large round overlay layout id mismatch");
        return false;
    }
    if (RugbyLayoutSupport.getLayoutId("rect", true) != "OverlayLayoutRect") {
        logger.error("rect overlay layout id mismatch");
        return false;
    }
    return true;
}
