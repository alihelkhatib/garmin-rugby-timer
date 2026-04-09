using Toybox.Test;
using Toybox.Lang;
using Toybox.Graphics;
using Rez.Drawables;
using Rez.Strings;

/*
Presentation-layer regression tests for the XML-first live screen.

Purpose: validate family-driven visibility and helper output now that XML owns
screen geometry and the renderer only maps model state into drawable content.
*/

class TestRendererModel {
    var gameState;
    var countdownRemaining;
    var countdownSeconds;
    var elapsedTime;
    var halfNumber;
    var homeTries;
    var awayTries;
    var suspensionTime;
    var yellowHomeTimes;
    var yellowAwayTimes;
    var redHomeTimes;
    var redAwayTimes;
    var redHomePermanent;
    var redAwayPermanent;
    var redHomeLabelCounter;
    var redAwayLabelCounter;

    function initialize(stateValue) {
        gameState = stateValue;
        countdownRemaining = 2400;
        countdownSeconds = 45;
        elapsedTime = 125;
        halfNumber = 1;
        homeTries = 2;
        awayTries = 1;
        suspensionTime = 0;
        yellowHomeTimes = [];
        yellowAwayTimes = [];
        redHomeTimes = [];
        redAwayTimes = [];
        redHomePermanent = false;
        redAwayPermanent = false;
        redHomeLabelCounter = 0;
        redAwayLabelCounter = 0;
    }

    function formatShortTime(seconds) {
        if (seconds <= 0) {
            return "--";
        }
        var mins = (seconds.toLong() / 60);
        var secs = (seconds.toLong() % 60);
        return mins.toString() + ":" + secs.format("%02d");
    }
}

class TestLayoutFamilySpec {
    var family;
    var width;
    var height;
    var safeTopPct;
    var safeBottomPct;
    var safeSidePct;

    static function create(familyValue, widthValue, heightValue, safeTopPctValue, safeBottomPctValue, safeSidePctValue) {
        var spec = new TestLayoutFamilySpec();
        spec.family = familyValue;
        spec.width = widthValue;
        spec.height = heightValue;
        spec.safeTopPct = safeTopPctValue;
        spec.safeBottomPct = safeBottomPctValue;
        spec.safeSidePct = safeSidePctValue;
        return spec;
    }
}

class TestLayoutNode {
    var id;
    var xPct;
    var yPct;
    var widthPx;
    var heightPx;
    var justify;

    static function create(idValue, xPctValue, yPctValue, widthPxValue, heightPxValue, justifyValue) {
        var node = new TestLayoutNode();
        node.id = idValue;
        node.xPct = xPctValue;
        node.yPct = yPctValue;
        node.widthPx = widthPxValue;
        node.heightPx = heightPxValue;
        node.justify = justifyValue;
        return node;
    }
}

class TestLayoutBounds {
    var left;
    var right;
    var top;
    var bottom;

    static function create(leftValue, rightValue, topValue, bottomValue) {
        var bounds = new TestLayoutBounds();
        bounds.left = leftValue;
        bounds.right = rightValue;
        bounds.top = topValue;
        bounds.bottom = bottomValue;
        return bounds;
    }
}

function getMainLayoutSafetySpec(family) {
    if (family == "compact_round") {
        return TestLayoutFamilySpec.create(family, 240, 240, 6, 5, 10);
    }
    if (family == "large_round") {
        return TestLayoutFamilySpec.create(family, 260, 260, 6, 5, 10);
    }
    return TestLayoutFamilySpec.create(family, 205, 148, 4, 4, 5);
}

function getOverlayLayoutSafetySpec(family) {
    return getMainLayoutSafetySpec(family);
}

function getMainCoreNodesForFamily(family) {
    if (family == "compact_round") {
        return [
            TestLayoutNode.create("ElapsedTimer", 50, 7, 46, 12, "center"),
            TestLayoutNode.create("HomeLabel", 26, 18, 34, 12, "center"),
            TestLayoutNode.create("AwayLabel", 74, 18, 34, 12, "center"),
            TestLayoutNode.create("HomeScore", 26, 28, 52, 34, "center"),
            TestLayoutNode.create("AwayScore", 74, 28, 52, 34, "center"),
            TestLayoutNode.create("HomeTries", 14, 34, 24, 12, "left"),
            TestLayoutNode.create("AwayTries", 86, 34, 24, 12, "right"),
            TestLayoutNode.create("HalfText", 50, 43, 44, 12, "center"),
            TestLayoutNode.create("HomeCardLabel", 29, 50, 16, 12, "right"),
            TestLayoutNode.create("HomeCardValue", 31, 50, 26, 12, "left"),
            TestLayoutNode.create("AwayCardLabel", 69, 50, 16, 12, "right"),
            TestLayoutNode.create("AwayCardValue", 71, 50, 26, 12, "left"),
            TestLayoutNode.create("Countdown", 50, 57, 126, 42, "center"),
            TestLayoutNode.create("StateLine1", 50, 77, 68, 12, "center"),
            TestLayoutNode.create("StateLine2", 50, 83, 22, 12, "center"),
            TestLayoutNode.create("HintLine1", 50, 88, 110, 12, "center"),
            TestLayoutNode.create("HintLine2", 50, 93, 108, 12, "center")
        ];
    }
    if (family == "large_round") {
        return [
            TestLayoutNode.create("ElapsedTimer", 50, 6, 54, 14, "center"),
            TestLayoutNode.create("HomeLabel", 27, 16, 36, 12, "center"),
            TestLayoutNode.create("AwayLabel", 73, 16, 36, 12, "center"),
            TestLayoutNode.create("HomeScore", 27, 25, 56, 34, "center"),
            TestLayoutNode.create("AwayScore", 73, 25, 56, 34, "center"),
            TestLayoutNode.create("HomeTries", 16, 32, 34, 16, "left"),
            TestLayoutNode.create("AwayTries", 84, 32, 34, 16, "right"),
            TestLayoutNode.create("HalfText", 50, 40, 48, 12, "center"),
            TestLayoutNode.create("HomeCardLabel", 31, 49, 20, 16, "right"),
            TestLayoutNode.create("HomeCardValue", 33, 49, 34, 16, "left"),
            TestLayoutNode.create("AwayCardLabel", 67, 49, 20, 16, "right"),
            TestLayoutNode.create("AwayCardValue", 69, 49, 34, 16, "left"),
            TestLayoutNode.create("Countdown", 50, 56, 136, 42, "center"),
            TestLayoutNode.create("StateLine1", 50, 77, 84, 16, "center"),
            TestLayoutNode.create("StateLine2", 50, 83, 28, 16, "center"),
            TestLayoutNode.create("HintLine1", 50, 89, 114, 12, "center"),
            TestLayoutNode.create("HintLine2", 50, 94, 112, 12, "center")
        ];
    }
    return [
        TestLayoutNode.create("ElapsedTimer", 50, 5, 54, 14, "center"),
        TestLayoutNode.create("HomeLabel", 24, 14, 42, 16, "center"),
        TestLayoutNode.create("AwayLabel", 76, 14, 42, 16, "center"),
        TestLayoutNode.create("HomeScore", 24, 23, 56, 34, "center"),
        TestLayoutNode.create("AwayScore", 76, 23, 56, 34, "center"),
        TestLayoutNode.create("HomeTries", 10, 30, 34, 16, "left"),
        TestLayoutNode.create("AwayTries", 90, 30, 34, 16, "right"),
        TestLayoutNode.create("HalfText", 50, 38, 48, 12, "center"),
        TestLayoutNode.create("HomeCardLabel", 27, 47, 20, 16, "right"),
        TestLayoutNode.create("HomeCardValue", 29, 47, 34, 16, "left"),
        TestLayoutNode.create("AwayCardLabel", 71, 47, 20, 16, "right"),
        TestLayoutNode.create("AwayCardValue", 73, 47, 34, 16, "left"),
        TestLayoutNode.create("Countdown", 50, 54, 136, 42, "center"),
        TestLayoutNode.create("StateLine1", 50, 77, 84, 16, "center"),
        TestLayoutNode.create("StateLine2", 50, 84, 28, 16, "center"),
        TestLayoutNode.create("HintLine1", 50, 90, 114, 12, "center"),
        TestLayoutNode.create("HintLine2", 50, 95, 112, 12, "center")
    ];
}

function getOverlayCoreNodesForFamily(family) {
    if (family == "compact_round") {
        return [
            TestLayoutNode.create("OverlayMainCountdown", 50, 9, 120, 34, "center"),
            TestLayoutNode.create("OverlayStateLabel", 50, 32, 84, 16, "center"),
            TestLayoutNode.create("OverlayCountdown", 50, 48, 128, 42, "center"),
            TestLayoutNode.create("OverlayHint", 50, 84, 116, 12, "center")
        ];
    }
    if (family == "large_round") {
        return [
            TestLayoutNode.create("OverlayMainCountdown", 50, 8, 120, 34, "center"),
            TestLayoutNode.create("OverlayStateLabel", 50, 30, 84, 16, "center"),
            TestLayoutNode.create("OverlayCountdown", 50, 46, 136, 42, "center"),
            TestLayoutNode.create("OverlayHint", 50, 84, 116, 12, "center")
        ];
    }
    return [
        TestLayoutNode.create("OverlayMainCountdown", 50, 7, 120, 34, "center"),
        TestLayoutNode.create("OverlayStateLabel", 50, 27, 84, 16, "center"),
        TestLayoutNode.create("OverlayCountdown", 50, 44, 136, 42, "center"),
        TestLayoutNode.create("OverlayHint", 50, 84, 116, 12, "center")
    ];
}

function getNodeBounds(spec, node) {
    var centerX = (spec.width * node.xPct) / 100.0f;
    var centerY = (spec.height * node.yPct) / 100.0f;
    var left = centerX;
    var right = centerX;
    if (node.justify == "center") {
        left = centerX - (node.widthPx / 2.0f);
        right = centerX + (node.widthPx / 2.0f);
    } else if (node.justify == "left") {
        right = centerX + node.widthPx;
    } else {
        left = centerX - node.widthPx;
    }
    var top = centerY - (node.heightPx / 2.0f);
    var bottom = centerY + (node.heightPx / 2.0f);
    return TestLayoutBounds.create(left, right, top, bottom);
}

function findNodeById(nodes, id) {
    if (!(nodes instanceof Lang.Array)) {
        return null;
    }
    var layoutNodes = nodes as Lang.Array;
    for (var i = 0; i < layoutNodes.size(); i = i + 1) {
        var node = layoutNodes[i] as TestLayoutNode;
        if (node != null && node.id == id) {
            return node;
        }
    }
    return null;
}

function assertNodeBoundsStayVisible(logger, spec, node) {
    var bounds = getNodeBounds(spec, node);
    if (bounds.left < 0 || bounds.right > spec.width || bounds.top < 0 || bounds.bottom > spec.height) {
        logger.error(spec.family + " " + node.id + " escaped screen bounds");
        return false;
    }
    var safeLeft = (spec.width * spec.safeSidePct) / 100.0f;
    var safeRight = spec.width - safeLeft;
    var safeTop = (spec.height * spec.safeTopPct) / 100.0f;
    var safeBottom = spec.height - ((spec.height * spec.safeBottomPct) / 100.0f);
    var anchorX = (spec.width * node.xPct) / 100.0f;
    var anchorY = (spec.height * node.yPct) / 100.0f;
    if (anchorX < safeLeft || anchorX > safeRight) {
        logger.error(spec.family + " " + node.id + " anchor drifted into bezel-risk side area");
        return false;
    }
    if (anchorY < safeTop || anchorY > safeBottom) {
        logger.error(spec.family + " " + node.id + " anchor drifted into bezel-risk top/bottom area");
        return false;
    }
    return true;
}

function assertVerticalOrder(logger, spec, nodes, firstId, secondId, gapPx) {
    var first = findNodeById(nodes, firstId);
    var second = findNodeById(nodes, secondId);
    if (first == null || second == null) {
        logger.error("missing node for vertical-order test");
        return false;
    }
    var firstBounds = getNodeBounds(spec, first);
    var secondBounds = getNodeBounds(spec, second);
    if (firstBounds.bottom + gapPx > secondBounds.top) {
        logger.error(spec.family + " " + firstId + " overlaps or crowds " + secondId);
        return false;
    }
    return true;
}

function assertHorizontalGap(logger, spec, nodes, leftId, rightId, gapPx) {
    var leftNode = findNodeById(nodes, leftId);
    var rightNode = findNodeById(nodes, rightId);
    if (leftNode == null || rightNode == null) {
        logger.error("missing node for horizontal-gap test");
        return false;
    }
    var leftBounds = getNodeBounds(spec, leftNode);
    var rightBounds = getNodeBounds(spec, rightNode);
    if (leftBounds.right + gapPx > rightBounds.left) {
        logger.error(spec.family + " " + leftId + " overlaps or crowds " + rightId);
        return false;
    }
    return true;
}

function assertCenterLaneSeparation(logger, spec, nodes, leftId, rightId, gapPx) {
    var centerX = spec.width / 2.0f;
    var leftNode = findNodeById(nodes, leftId);
    var rightNode = findNodeById(nodes, rightId);
    if (leftNode == null || rightNode == null) {
        logger.error("missing node for center-lane test");
        return false;
    }
    var leftBounds = getNodeBounds(spec, leftNode);
    var rightBounds = getNodeBounds(spec, rightNode);
    if (leftBounds.right + gapPx > centerX) {
        logger.error(spec.family + " " + leftId + " crossed the center lane");
        return false;
    }
    if (rightBounds.left - gapPx < centerX) {
        logger.error(spec.family + " " + rightId + " crossed the center lane");
        return false;
    }
    return true;
}

(:test)
function test_renderer_compact_family_hides_icons_and_tries(logger as Test.Logger) as Lang.Boolean {
    if (RugbyTimerRenderer.shouldShowIcons("compact_round")) {
        logger.error("compact round should hide icons");
        return false;
    }
    if (RugbyTimerRenderer.shouldShowTries("compact_round")) {
        logger.error("compact round should hide tries");
        return false;
    }
    return true;
}

(:test)
function test_renderer_large_family_shows_icons_and_tries(logger as Test.Logger) as Lang.Boolean {
    if (!RugbyTimerRenderer.shouldShowIcons("large_round")) {
        logger.error("large round should show icons");
        return false;
    }
    if (!RugbyTimerRenderer.shouldShowTries("rect")) {
        logger.error("rectangular layout should show tries");
        return false;
    }
    return true;
}

(:test)
function test_renderer_text_helpers_format_scoreboard_strings(logger as Test.Logger) as Lang.Boolean {
    var model = new TestRendererModel(STATE_PLAYING);
    if (RugbyTimerRenderer.getElapsedTimerText(model) != "02:05") {
        logger.error("elapsed timer text mismatch");
        return false;
    }
    if (RugbyTimerRenderer.getCountdownText(model) != "40:00") {
        logger.error("countdown text mismatch");
        return false;
    }
    if (RugbyTimerRenderer.getHalfText(model) != RugbyStrings.getHalfText(1)) {
        logger.error("half text mismatch");
        return false;
    }
    return RugbyTimerRenderer.getHomeTriesText(model) == RugbyStrings.getTryText(2)
        && RugbyTimerRenderer.getAwayTriesText(model) == RugbyStrings.getTryText(1);
}

(:test)
function test_renderer_state_mapping_for_paused(logger as Test.Logger) as Lang.Boolean {
    var model = new TestRendererModel(STATE_PAUSED);
    if (RugbyTimerRenderer.getMainStateLine1(model) != RugbyStrings.load(Rez.Strings.State_Paused)) {
        logger.error("paused line 1 mismatch");
        return false;
    }
    if (RugbyTimerRenderer.getMainStateLine2(model) != "") {
        logger.error("paused line 2 should be hidden");
        return false;
    }
    return RugbyTimerRenderer.getMainStateColor(model) == Graphics.COLOR_RED;
}

(:test)
function test_renderer_state_mapping_for_conversion(logger as Test.Logger) as Lang.Boolean {
    var model = new TestRendererModel(STATE_CONVERSION);
    if (RugbyTimerRenderer.getMainStateLine1(model) != RugbyStrings.load(Rez.Strings.State_Conversion)) {
        logger.error("conversion line 1 mismatch");
        return false;
    }
    if (RugbyTimerRenderer.getMainStateLine2(model) != RugbyStrings.getSecondsText(45)) {
        logger.error("conversion line 2 mismatch");
        return false;
    }
    return RugbyTimerRenderer.getMainStateColor(model) == Graphics.COLOR_RED;
}

(:test)
function test_renderer_hint_mode_covers_locked_idle_and_hidden(logger as Test.Logger) as Lang.Boolean {
    if (RugbyTimerRenderer.getHintMode(STATE_PLAYING, true, true) != "locked") {
        logger.error("locked hint mode mismatch");
        return false;
    }
    if (RugbyTimerRenderer.getHintMode(STATE_IDLE, false, true) != "idle") {
        logger.error("idle hint mode mismatch");
        return false;
    }
    if (RugbyTimerRenderer.getHintMode(STATE_PLAYING, false, true) != "hidden") {
        logger.error("playing hint mode should be hidden");
        return false;
    }
    return true;
}

(:test)
function test_renderer_teamCardPresentation_prefers_urgent_timed_card(logger as Test.Logger) as Lang.Boolean {
    var model = new TestRendererModel(STATE_PLAYING);
    model.yellowHomeTimes = [{ "remaining" => 300, "label" => "Y1", "cardId" => 1 }];
    model.redHomePermanent = true;

    var card = RugbyTimerRenderer.getTeamCardPresentation(
        model,
        model.yellowHomeTimes,
        model.redHomeTimes,
        model.redHomePermanent,
        1
    );
    if (!card.visible) {
        logger.error("urgent timed card should be visible");
        return false;
    }
    if (card.label != "Y1" || card.value != "5:00") {
        logger.error("urgent timed card content mismatch");
        return false;
    }
    return card.color == Graphics.COLOR_YELLOW;
}

(:test)
function test_renderer_teamCardPresentation_falls_back_to_perm_red(logger as Test.Logger) as Lang.Boolean {
    var model = new TestRendererModel(STATE_PLAYING);
    model.redAwayPermanent = true;
    model.redAwayLabelCounter = 2;

    var card = RugbyTimerRenderer.getTeamCardPresentation(
        model,
        model.yellowAwayTimes,
        model.redAwayTimes,
        model.redAwayPermanent,
        model.redAwayLabelCounter
    );
    if (!card.visible) {
        logger.error("permanent red card should be visible");
        return false;
    }
    if (card.label != "R2" || card.value != "PERM") {
        logger.error("permanent red card content mismatch");
        return false;
    }
    return card.color == Graphics.COLOR_RED;
}


(:test)
function test_overlay_helpers_return_expected_text_and_hint(logger as Test.Logger) as Lang.Boolean {
    var model = new TestRendererModel(STATE_CONVERSION);
    if (RugbyTimerOverlay.getOverlayMainCountdownText(model) != "40:00") {
        logger.error("overlay main countdown mismatch");
        return false;
    }
    if (RugbyTimerOverlay.getOverlayCountdownText(model) != "00:45") {
        logger.error("overlay special countdown mismatch");
        return false;
    }
    if (RugbyTimerOverlay.getSpecialStateLabel(model) != RugbyStrings.load(Rez.Strings.State_Conversion)) {
        logger.error("overlay state label mismatch");
        return false;
    }
    return RugbyTimerOverlay.getSpecialOverlayHint(model) == RugbyStrings.load(Rez.Strings.Overlay_Hint_Conversion);
}

(:test)
function test_mainLayout_core_nodes_stay_on_screen_and_out_of_bezel_risk(logger as Test.Logger) as Lang.Boolean {
    var families = ["compact_round", "large_round", "rect"];
    for (var i = 0; i < families.size(); i = i + 1) {
        var family = families[i];
        var spec = getMainLayoutSafetySpec(family);
        var nodes = getMainCoreNodesForFamily(family) as Lang.Array;
        for (var j = 0; j < nodes.size(); j = j + 1) {
            var node = nodes[j] as TestLayoutNode;
            if (!assertNodeBoundsStayVisible(logger, spec, node)) {
                return false;
            }
        }
    }
    return true;
}

(:test)
function test_mainLayout_core_rows_keep_vertical_separation(logger as Test.Logger) as Lang.Boolean {
    var families = ["compact_round", "large_round", "rect"];
    for (var i = 0; i < families.size(); i = i + 1) {
        var family = families[i];
        var spec = getMainLayoutSafetySpec(family);
        var nodes = getMainCoreNodesForFamily(family);
        if (!assertVerticalOrder(logger, spec, nodes, "ElapsedTimer", "HomeLabel", 2)) { return false; }
        if (!assertVerticalOrder(logger, spec, nodes, "HomeLabel", "HomeScore", 2)) { return false; }
        if (!assertVerticalOrder(logger, spec, nodes, "HomeScore", "HalfText", 2)) { return false; }
        if (!assertVerticalOrder(logger, spec, nodes, "HalfText", "HomeCardValue", 2)) { return false; }
        if (!assertVerticalOrder(logger, spec, nodes, "HomeCardValue", "Countdown", 6)) { return false; }
        if (!assertVerticalOrder(logger, spec, nodes, "Countdown", "StateLine1", 6)) { return false; }
        if (!assertVerticalOrder(logger, spec, nodes, "StateLine1", "StateLine2", 2)) { return false; }
        if (!assertVerticalOrder(logger, spec, nodes, "StateLine2", "HintLine1", 2)) { return false; }
        if (!assertVerticalOrder(logger, spec, nodes, "HintLine1", "HintLine2", 1)) { return false; }
    }
    return true;
}

(:test)
function test_mainLayout_same_row_objects_keep_horizontal_separation(logger as Test.Logger) as Lang.Boolean {
    var families = ["compact_round", "large_round", "rect"];
    for (var i = 0; i < families.size(); i = i + 1) {
        var family = families[i];
        var spec = getMainLayoutSafetySpec(family);
        var nodes = getMainCoreNodesForFamily(family);
        if (!assertHorizontalGap(logger, spec, nodes, "HomeTries", "HomeScore", 2)) { return false; }
        if (!assertHorizontalGap(logger, spec, nodes, "HomeCardLabel", "HomeCardValue", 2)) { return false; }
        if (!assertHorizontalGap(logger, spec, nodes, "AwayScore", "AwayTries", 2)) { return false; }
        if (!assertHorizontalGap(logger, spec, nodes, "AwayCardLabel", "AwayCardValue", 2)) { return false; }
        if (!assertCenterLaneSeparation(logger, spec, nodes, "HomeScore", "AwayScore", 6)) { return false; }
        if (!assertCenterLaneSeparation(logger, spec, nodes, "HomeCardValue", "AwayCardLabel", 6)) { return false; }
    }
    return true;
}

(:test)
function test_overlayLayout_core_nodes_stay_on_screen_and_separated(logger as Test.Logger) as Lang.Boolean {
    var families = ["compact_round", "large_round", "rect"];
    for (var i = 0; i < families.size(); i = i + 1) {
        var family = families[i];
        var spec = getOverlayLayoutSafetySpec(family);
        var nodes = getOverlayCoreNodesForFamily(family) as Lang.Array;
        for (var j = 0; j < nodes.size(); j = j + 1) {
            var node = nodes[j] as TestLayoutNode;
            if (!assertNodeBoundsStayVisible(logger, spec, node)) {
                return false;
            }
        }
        if (!assertVerticalOrder(logger, spec, nodes, "OverlayMainCountdown", "OverlayStateLabel", 4)) { return false; }
        if (!assertVerticalOrder(logger, spec, nodes, "OverlayStateLabel", "OverlayCountdown", 4)) { return false; }
        if (!assertVerticalOrder(logger, spec, nodes, "OverlayCountdown", "OverlayHint", 8)) { return false; }
    }
    return true;
}
