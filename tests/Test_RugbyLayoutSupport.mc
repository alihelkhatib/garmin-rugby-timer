using Toybox.Test;
using Toybox.Lang;

/*
Unit tests for layout-guide fallback behavior.

Purpose: keep the hybrid XML + renderer layout model conservative when XML
metadata is unavailable.
*/

(:test)
function test_layoutSupport_resolveGuide_returns_compact_round_fallback(logger as Test.Logger) as Lang.Boolean {
    var guide = RugbyLayoutSupport.resolveGuide(null, "compact_round");
    if (guide == null) {
        logger.error("compact round guide was null");
        return false;
    }
    if (guide.family != "compact_round") {
        logger.error("unexpected compact round family: " + guide.family);
        return false;
    }
    return true;
}

(:test)
function test_layoutSupport_resolveGuide_returns_large_round_fallback(logger as Test.Logger) as Lang.Boolean {
    var guide = RugbyLayoutSupport.resolveGuide(null, "large_round");
    if (guide == null) {
        logger.error("large round guide was null");
        return false;
    }
    if (guide.family != "large_round") {
        logger.error("unexpected large round family: " + guide.family);
        return false;
    }
    return true;
}

(:test)
function test_layoutSupport_resolveGuide_returns_rectangular_fallback(logger as Test.Logger) as Lang.Boolean {
    var guide = RugbyLayoutSupport.resolveGuide(null, "rect");
    if (guide == null) {
        logger.error("rect guide was null");
        return false;
    }
    if (guide.family != "rect") {
        logger.error("unexpected rect family: " + guide.family);
        return false;
    }
    return true;
}

(:test)
function test_layoutSupport_fallback_safe_insets_stay_conservative(logger as Test.Logger) as Lang.Boolean {
    var roundGuide = RugbyLayoutSupport.resolveGuide(null, "compact_round");
    var rectGuide = RugbyLayoutSupport.resolveGuide(null, "rect");
    if (!(roundGuide.safeTopPct > rectGuide.safeTopPct)) {
        logger.error("round fallback should reserve more top safe area than rectangular");
        return false;
    }
    if (!(roundGuide.safeSidePct > rectGuide.safeSidePct)) {
        logger.error("round fallback should reserve more side inset than rectangular");
        return false;
    }
    return true;
}
