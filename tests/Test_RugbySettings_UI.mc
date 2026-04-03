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
    var pendingProfileId;

    function initialize(m) {
        model = m;
        pendingProfileId = null;
    }

    function resolveProfileId(itemId) {
        var idText = itemId != null ? itemId.toString() : "";
        if (itemId == "7s" || idText == "7s" || itemId == :profile_7s || idText == "profile_7s" || idText == ":profile_7s") {
            return "7s";
        } else if (itemId == "10s" || idText == "10s" || itemId == :profile_10s || idText == "profile_10s" || idText == ":profile_10s") {
            return "10s";
        } else if (itemId == "15s" || idText == "15s" || itemId == :profile_15s || idText == "profile_15s" || idText == ":profile_15s") {
            return "15s";
        } else if (itemId == "u19" || idText == "u19" || itemId == :profile_u19 || idText == "profile_u19" || idText == ":profile_u19") {
            return "u19";
        } else if (itemId == "custom" || idText == "custom" || itemId == :profile_custom || idText == "profile_custom" || idText == ":profile_custom") {
            return "custom";
        }
        return null;
    }

    function onSelect(item) {
        var profileId = resolveProfileId(item.getId());
        if (profileId == null) { return; }
        pendingProfileId = profileId;
        // Simulate timer callback immediately in headless tests
        applyPendingProfile();
    }

    function applyPendingProfile() {
        var profileId = pendingProfileId;
        pendingProfileId = null;
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
        var minutes = values[0] * 10 + values[1];
        if (minutes < 1) { minutes = 1; }
        model.setHalfDuration(minutes * 60);
        return true;
    }
}

class TestConversionAdjustDelegate {
    var model;
    function initialize(m) { model = m; }
    function onSelect(item) {
        var val = 30;
        var id = item.getId();
        if (id == "t60" || id == :t60) { val = 60; }
        else if (id == "t90" || id == :t90) { val = 90; }
        else if (id == "t120" || id == :t120) { val = 120; }
        model.setConversionTime(val);
    }
}

function clearCustomStorage() {
    Storage.setValue("customHalfDuration", null);
    Storage.setValue("customConversionTime", null);
    Storage.setValue("customKickoffTime", null);
    Storage.setValue("customPenaltyKickTime", null);
    Storage.setValue("customUseConversionTimer", null);
    Storage.setValue("customUsePenaltyTimer", null);
    Storage.setValue("customProfileIs7s", null);
    Storage.setValue("matchProfileId", null);
}

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
    return (model.matchProfileId == "custom") && (Storage.getValue("matchProfileId") == "custom");
}
