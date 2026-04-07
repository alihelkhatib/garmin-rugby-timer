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

// shared helper `clearCustomStorage` moved to tests/TestHelpers.mc

(:test)
function test_ui_minutes_picker_sets_half_duration(logger as Test.Logger) as Lang.Boolean {
    // Purpose: MinutesPicker acceptance should set the model half duration (minutes*60).
    var model = new RugbyGameModel();
    model.initialize();

    var p = new TestTimerPickerDelegate(model);
    var ok = p.onAccept([2,5]); // 25 minutes
    if (!ok) { return false; }
    return model.halfDuration == 25 * 60 && model.countdownTimer == 25 * 60;
}

(:test)
function test_ui_conversion_adjust_changes_value(logger as Test.Logger) as Lang.Boolean {
    // Purpose: Conversion adjust menu entries update the model.conversionTime.
    var model = new RugbyGameModel();
    model.initialize();

    var c = new TestConversionAdjustDelegate(model);
    var item = new TestMenuItem("t120");
    c.onSelect(item);
    return model.conversionTime == 120;
}

(:test)
function test_ui_toggle_format_updates_live_ruleset(logger as Test.Logger) as Lang.Boolean {
    // Purpose: toggling Format Family should directly update the active ruleset.
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    model.setFormatFamily(true);
    if (!model.usesSevensCardRules() || model.halfDuration != 420 || model.conversionTime != 30) {
        return false;
    }

    model.setFormatFamily(false);
    return !model.usesSevensCardRules() && model.halfDuration == 2400 && model.conversionTime == 90;
}

(:test)
function test_settings_support_minutes_and_timer_mapping(logger as Test.Logger) as Lang.Boolean {
    if (RugbySettingsSupport.clampMinutes(0) != 1) { logger.error("minutes clamp low failed"); return false; }
    if (RugbySettingsSupport.clampMinutes(120) != 99) { logger.error("minutes clamp high failed"); return false; }
    if (RugbySettingsSupport.getMinutesFromDigits([0, 5]) != 5) { logger.error("digits mapping failed"); return false; }
    return RugbySettingsSupport.getConversionSelectionSeconds("t120") == 120;
}

(:test)
function test_settings_support_choice_resolution(logger as Test.Logger) as Lang.Boolean {
    if (RugbySettingsSupport.resolveFormatFamily(:format_7s) != true) { logger.error("format 7s resolution failed"); return false; }
    if (RugbySettingsSupport.resolveFormatFamily(:format_15s) != false) { logger.error("format 15s resolution failed"); return false; }
    if (RugbySettingsSupport.resolveMatchFormatId(:match_format_10s) != "10s") { logger.error("match format 10s resolution failed"); return false; }
    if (RugbySettingsSupport.resolveMatchFormatId(:match_format_u19) != "u19") { logger.error("match format u19 resolution failed"); return false; }
    return RugbySettingsSupport.resolveTeamLabelMode(:team_label_red_blue) == TEAM_LABEL_MODE_RED_BLUE;
}

(:test)
function test_settings_match_format_label_from_live_values(logger as Test.Logger) as Lang.Boolean {
    if (RugbySettingsSupport.getMatchFormatLabelForValues(true, 420) != "7s") { logger.error("420 / sevens should show 7s"); return false; }
    if (RugbySettingsSupport.getMatchFormatLabelForValues(false, 600) != "10s") { logger.error("600 should show 10s"); return false; }
    if (RugbySettingsSupport.getMatchFormatLabelForValues(false, 2400) != "15s") { logger.error("2400 should show 15s"); return false; }
    if (RugbySettingsSupport.getMatchFormatLabelForValues(false, 2100) != "U19s") { logger.error("2100 should show U19s"); return false; }
    return RugbySettingsSupport.getMatchFormatLabelForValues(false, 1500) == "Custom";
}

(:test)
function test_settings_display_state_tracks_live_preset_rules(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.setMatchProfile("7s");

    var state = RugbySettingsSupport.buildDisplayState(model, null, true, false);
    if (state.matchFormatLabel != "7s") { logger.error("live format label should show 7s"); return false; }
    if (state.conversionLabel != "00:30") { logger.error("7s conversion label should be 00:30"); return false; }
    if (state.halftimeBreakLabel != "00:30") { logger.error("7s halftime label should be 00:30"); return false; }
    if (state.penaltyLabel != "01:00") { logger.error("7s penalty label should be 01:00"); return false; }
    if (state.useConversionLabel != "On") { logger.error("7s conversion overlay should be On"); return false; }
    if (state.usePenaltyLabel != "Off") { logger.error("7s penalty overlay should be Off"); return false; }
    if (state.lockOnStartLabel != "On") { logger.error("lock label mismatch"); return false; }
    return state.dimThemeLabel == "Off";
}

(:test)
function test_settings_display_state_tracks_live_customized_rules_and_labels(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();
    model.setMatchProfile("15s");
    model.setConversionTime(120);
    model.setPenaltyKickTime(90);
    model.setConversionTimerEnabled(false);
    model.setPenaltyTimerEnabled(true);
    model.setTeamLabelMode(TEAM_LABEL_MODE_RED_BLUE);

    var state = RugbySettingsSupport.buildDisplayState(model, null, false, true);
    if (state.matchFormatLabel != "15s") { logger.error("format label should still follow live 15s structure"); return false; }
    if (state.conversionLabel != "02:00") { logger.error("conversion label should reflect custom value"); return false; }
    if (state.halftimeBreakLabel != "01:00") { logger.error("halftime break should reflect live kickoff value"); return false; }
    if (state.penaltyLabel != "01:30") { logger.error("penalty label should reflect custom value"); return false; }
    if (state.useConversionLabel != "Off") { logger.error("conversion overlay label should be Off"); return false; }
    if (state.usePenaltyLabel != "On") { logger.error("penalty overlay label should be On"); return false; }
    if (state.teamLabelsLabel != "Red / Blue") { logger.error("team labels row should reflect selected preset"); return false; }
    if (state.dimThemeLabel != "On") { logger.error("dim label mismatch"); return false; }
    if (RugbyTeamIdentitySupport.getTeamLabel(model, true) != "Red") { logger.error("home team label propagation mismatch"); return false; }
    return RugbyTeamIdentitySupport.getTeamLabel(model, false) == "Blue";
}
