using Toybox.Test;
using Toybox.Lang;
using Toybox.Application.Storage;

/*
Headless UI tests for Settings flows.

Purpose: simulate selection and picker interactions without the WatchUi runtime
by invoking small test-only delegate helpers that operate directly on the model.
*/

class TestMenuItem {
    var id;
    function initialize(i) { id = i; }
    function getId() { return id; }
}

class TestMatchProfileDelegate {
    var model;

    function initialize(m) {
        model = m;
    }

    function resolveProfileId(itemId) {
        return RugbySettingsSupport.resolveProfileId(itemId);
    }

    function onSelect(item) {
        var profileId = resolveProfileId(item.getId());
        if (profileId == null) { return; }
        if (model == null || profileId == null) { return; }
        if (model.gameState != STATE_IDLE) {
            // Idle-only enforcement — do nothing when in-game
            return;
        }
        model.setMatchProfile(profileId);
    }
}

class TestTimerPickerDelegate {
    var model;
    function initialize(m) { model = m; }
    function onAccept(values) {
        var minutes = RugbySettingsSupport.getMinutesFromDigits(values);
        model.setHalfDuration(minutes * 60);
        return true;
    }
}

class TestConversionAdjustDelegate {
    var model;
    function initialize(m) { model = m; }
    function onSelect(item) {
        var val = RugbySettingsSupport.getConversionSelectionSeconds(item.getId());
        model.setConversionTime(val);
    }
}

class TestSettingsMenuProjection {
    var profileLabel;
    var halfLabel;
    var conversionLabel;
    var penaltyLabel;

    static function create(model) {
        var projection = new TestSettingsMenuProjection();
        var profile = model.buildCurrentProfile(model.matchProfileId);
        projection.profileLabel = RugbySettingsSupport.getProfileLabel(profile);
        projection.halfLabel = formatSeconds(RugbySettingsSupport.getProfileEntry(profile).halfDuration);
        projection.conversionLabel = formatSeconds(RugbySettingsSupport.getProfileEntry(profile).conversionTime);
        projection.penaltyLabel = formatSeconds(RugbySettingsSupport.getProfileEntry(profile).penaltyKickTime);
        return projection;
    }
}

function formatSeconds(seconds) {
    if (seconds == null) { seconds = 0; }
    var mins = (seconds.toLong() / 60).toLong();
    var secs = (seconds.toLong() % 60).toLong();
    return mins.format("%02d") + ":" + secs.format("%02d");
}

// shared helper `clearCustomStorage` moved to tests/TestHelpers.mc

(:test)
function test_ui_select_profile_7s(logger as Test.Logger) as Lang.Boolean {
    // Purpose: selecting 'Rugby 7s' from the profile menu applies the 7s preset.
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    var d = new TestMatchProfileDelegate(model);
    var item = new TestMenuItem("profile_7s");
    d.onSelect(item);

    return (model.matchProfileId == "7s") && (model.halfDuration == 420) && (model.conversionTime == 30);
}

(:test)
function test_ui_rebuilt_settings_projection_for_7s(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    var d = new TestMatchProfileDelegate(model);
    d.onSelect(new TestMenuItem("profile_7s"));

    var projection = TestSettingsMenuProjection.create(model);
    if (projection.profileLabel != RugbyStrings.getProfileLabel("7s")) { logger.error("7s profile label mismatch"); return false; }
    if (projection.halfLabel != "07:00") { logger.error("7s half label mismatch"); return false; }
    if (projection.conversionLabel != "00:30") { logger.error("7s conversion label mismatch"); return false; }
    return projection.penaltyLabel == "01:00";
}

(:test)
function test_ui_rebuilt_settings_projection_for_u19(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    var d = new TestMatchProfileDelegate(model);
    d.onSelect(new TestMenuItem("profile_u19"));

    var projection = TestSettingsMenuProjection.create(model);
    if (projection.profileLabel != RugbyStrings.getProfileLabel("u19")) { logger.error("u19 profile label mismatch"); return false; }
    if (projection.halfLabel != "35:00") { logger.error("u19 half label mismatch"); return false; }
    if (projection.conversionLabel != "01:30") { logger.error("u19 conversion label mismatch"); return false; }
    return projection.penaltyLabel == "01:00";
}

(:test)
function test_ui_select_profile_while_playing_is_blocked(logger as Test.Logger) as Lang.Boolean {
    // Purpose: selecting a preset while a match is active should be ignored.
    var model = new RugbyGameModel();
    model.initialize();
    model.gameState = STATE_PLAYING;

    var original = model.matchProfileId;
    var d = new TestMatchProfileDelegate(model);
    var item = new TestMenuItem("profile_15s");
    d.onSelect(item);

    return (model.matchProfileId == original);
}

(:test)
function test_ui_minutes_picker_sets_half_duration(logger as Test.Logger) as Lang.Boolean {
    // Purpose: MinutesPicker acceptance should set the model half duration (minutes*60).
    var model = new RugbyGameModel();
    model.initialize();

    var p = new TestTimerPickerDelegate(model);
    var ok = p.onAccept([2,5]); // 25 minutes
    if (!ok) { return false; }
    return (model.halfDuration == 25 * 60) && (model.matchProfileId == "custom");
}

(:test)
function test_ui_rebuilt_settings_projection_for_custom_minutes(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    var p = new TestTimerPickerDelegate(model);
    if (!p.onAccept([2, 5])) { logger.error("minutes picker accept failed"); return false; }

    var projection = TestSettingsMenuProjection.create(model);
    if (projection.profileLabel != RugbyStrings.getProfileLabel("custom")) { logger.error("custom profile label mismatch"); return false; }
    return projection.halfLabel == "25:00";
}

(:test)
function test_ui_conversion_adjust_changes_value(logger as Test.Logger) as Lang.Boolean {
    // Purpose: Conversion adjust menu entries update the model.conversionTime.
    var model = new RugbyGameModel();
    model.initialize();

    var c = new TestConversionAdjustDelegate(model);
    var item = new TestMenuItem("t120");
    c.onSelect(item);
    return (model.conversionTime == 120) && (model.matchProfileId == "custom");
}

(:test)
function test_ui_toggle_format_promotes_to_custom(logger as Test.Logger) as Lang.Boolean {
    // Purpose: toggling Format Family should promote current settings to the custom profile.
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    // Start with a built-in
    model.applyProfile(RugbyMatchProfiles.getBuiltInProfile("15s"), false);
    if (model.matchProfileId == "custom") { return false; }

    model.setFormatFamily(true);
    model.flushPendingCustomProfileSave();
    return (model.matchProfileId == "custom") && (Storage.getValue(STORAGE_KEY_MATCH_PROFILE_ID) == "custom");
}

(:test)
function test_settings_support_profile_resolution_and_clamp(logger as Test.Logger) as Lang.Boolean {
    if (RugbySettingsSupport.resolveProfileId("profile_u19") != "u19") { logger.error("profile resolution failed"); return false; }
    if (RugbySettingsSupport.clampMinutes(0) != 1) { logger.error("minutes clamp low failed"); return false; }
    if (RugbySettingsSupport.clampMinutes(120) != 99) { logger.error("minutes clamp high failed"); return false; }
    return RugbySettingsSupport.getMinutesFromDigits([0, 5]) == 5;
}

(:test)
function test_settings_support_idle_hints_default_enabled_and_persisted(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    if (!RugbySettingsSupport.getStoredFlag(Storage.getValue(STORAGE_KEY_SHOW_IDLE_HINTS), true)) {
        logger.error("idle hints should default to enabled");
        return false;
    }

    Storage.setValue(STORAGE_KEY_SHOW_IDLE_HINTS, false);
    if (RugbySettingsSupport.getStoredFlag(Storage.getValue(STORAGE_KEY_SHOW_IDLE_HINTS), true)) {
        logger.error("idle hints persisted toggle was not respected");
        return false;
    }

    return true;
}
