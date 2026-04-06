using Toybox.Test;
using Toybox.Lang;
using Toybox.Application.Storage;

/*
Settings & MatchProfile tests

Purpose: verify built-in profiles, inference, custom profile persistence,
promotion-to-custom behavior, and card/red/yellow duration semantics.
*/

// shared helper `clearCustomStorage` moved to tests/TestHelpers.mc

(:test)
function test_builtin_profiles_values(logger as Test.Logger) as Lang.Boolean {
    // Purpose: built-in profiles expose expected timing defaults.
    var p7 = MatchProfileEntry.fromDict(RugbyMatchProfiles.getBuiltInProfile("7s"));
    if (p7 == null) { logger.error("7s profile missing"); return false; }
    if (p7.halfDuration != 420) { logger.error("7s halfDuration!=420"); return false; }
    if (p7.conversionTime != 30) { logger.error("7s conversionTime!=30"); return false; }
    if (p7.kickoffTime != 30) { logger.error("7s kickoffTime!=30"); return false; }
    if (p7.penaltyKickTime != 60) { logger.error("7s penaltyKickTime!=60"); return false; }
    if (p7.is7s != true) { logger.error("7s is7s flag not true"); return false; }

    var p15 = MatchProfileEntry.fromDict(RugbyMatchProfiles.getBuiltInProfile("15s"));
    if (p15 == null) { logger.error("15s profile missing"); return false; }
    if (p15.halfDuration != 2400) { logger.error("15s halfDuration!=2400"); return false; }
    if (p15.conversionTime != 90) { logger.error("15s conversionTime!=90"); return false; }
    if (p15.kickoffTime != 60) { logger.error("15s kickoffTime!=60"); return false; }
    if (p15.penaltyKickTime != 60) { logger.error("15s penaltyKickTime!=60"); return false; }
    if (p15.is7s == true) { logger.error("15s is7s flag unexpectedly true"); return false; }

    return true;
}

(:test)
function test_infer_profile_id_from_builtins(logger as Test.Logger) as Lang.Boolean {
    // Purpose: settings that exactly match built-ins should infer the built-in id.
    var p7 = MatchProfileEntry.fromDict(RugbyMatchProfiles.getBuiltInProfile("7s"));
    if (p7 == null) { logger.error("7s profile missing"); return false; }
    var id7 = RugbyMatchProfiles.inferProfileIdFromSettings(
        p7.is7s, p7.halfDuration, p7.conversionTime, p7.kickoffTime, p7.penaltyKickTime, p7.useConversionTimer, p7.usePenaltyTimer
    );
    if (id7 != "7s") { logger.error("inferProfileIdFromSettings did not return 7s for 7s settings: " + id7); return false; }

    var p10 = MatchProfileEntry.fromDict(RugbyMatchProfiles.getBuiltInProfile("10s"));
    if (p10 == null) { logger.error("10s profile missing"); return false; }
    if (p10.halfDuration != 600) { logger.error("10s halfDuration!=600"); return false; }
    var id10 = RugbyMatchProfiles.inferProfileIdFromSettings(
        p10.is7s, p10.halfDuration, p10.conversionTime, p10.kickoffTime, p10.penaltyKickTime, p10.useConversionTimer, p10.usePenaltyTimer
    );
    if (id10 != "10s") { logger.error("inferProfileIdFromSettings did not return 10s for 10s settings: " + id10); return false; }

    var pu19 = MatchProfileEntry.fromDict(RugbyMatchProfiles.getBuiltInProfile("u19"));
    if (pu19 == null) { logger.error("u19 profile missing"); return false; }
    if (pu19.halfDuration != 2100) { logger.error("u19 halfDuration!=2100"); return false; }
    var idu19 = RugbyMatchProfiles.inferProfileIdFromSettings(
        pu19.is7s, pu19.halfDuration, pu19.conversionTime, pu19.kickoffTime, pu19.penaltyKickTime, pu19.useConversionTimer, pu19.usePenaltyTimer
    );
    if (idu19 != "u19") { logger.error("inferProfileIdFromSettings did not return u19 for u19 settings: " + idu19); return false; }

    return true;
}

(:test)
function test_store_and_get_custom_profile(logger as Test.Logger) as Lang.Boolean {
    // Purpose: storeCustomProfile should persist custom timing fields and getStoredCustomProfile should read them back.
    clearCustomStorage();

    var custom = RugbyMatchProfiles.withTeamLabelMode(
        RugbyMatchProfiles.createProfile("custom", "MyVariant", false, 1800, 45, 50, 70, false, true),
        TEAM_LABEL_MODE_RED_BLUE
    );
    RugbyMatchProfiles.storeCustomProfile(custom);

    var s = MatchProfileEntry.fromDict(RugbyMatchProfiles.getStoredCustomProfile());
    if (s == null) { logger.error("stored custom missing"); return false; }
    if (s.halfDuration != 1800) { logger.error("stored halfDuration mismatch: " + s.halfDuration.toString()); return false; }
    if (s.conversionTime != 45) { logger.error("stored conversionTime mismatch: " + s.conversionTime.toString()); return false; }
    if (s.kickoffTime != 50) { logger.error("stored kickoffTime mismatch: " + s.kickoffTime.toString()); return false; }
    if (s.penaltyKickTime != 70) { logger.error("stored penaltyKickTime mismatch: " + s.penaltyKickTime.toString()); return false; }
    if (s.useConversionTimer != false) { logger.error("stored useConversionTimer mismatch"); return false; }
    if (s.usePenaltyTimer != true) { logger.error("stored usePenaltyTimer mismatch"); return false; }
    if (s.teamLabelMode != TEAM_LABEL_MODE_RED_BLUE) { logger.error("stored teamLabelMode mismatch"); return false; }

    return true;
}

(:test)
function test_setMatchProfile_creates_custom_when_missing(logger as Test.Logger) as Lang.Boolean {
    // Purpose: selecting "custom" should save the current model settings when no custom exists.
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    // Tweak model settings to known custom values
    model.halfDuration = 1234;
    model.countdownTimer = 1234;
    model.conversionTime = 44;
    model.kickoffTime = 55;
    model.penaltyKickTime = 66;
    model.useConversionTimer = false;
    model.usePenaltyTimer = true;
    model.teamLabelMode = TEAM_LABEL_MODE_TEAM_A_B;

    // Ensure no custom exists
    if (RugbyMatchProfiles.hasStoredCustomProfile()) {
        logger.debug("pre-existing custom profile unexpectedly found");
        return false;
    }

    model.setMatchProfile("custom");

    if (!RugbyMatchProfiles.hasStoredCustomProfile()) { logger.error("custom profile was not created"); return false; }
    var s = MatchProfileEntry.fromDict(RugbyMatchProfiles.getStoredCustomProfile());
    if (s == null) { logger.error("stored custom missing after setMatchProfile"); return false; }
    if (s.halfDuration != 1234) { logger.error("stored halfDuration mismatch after setMatchProfile: " + s.halfDuration.toString()); return false; }
    if (s.conversionTime != 44) { logger.error("stored conversionTime mismatch after setMatchProfile"); return false; }
    if (s.teamLabelMode != TEAM_LABEL_MODE_TEAM_A_B) { logger.error("stored teamLabelMode mismatch after setMatchProfile"); return false; }

    return true;
}

(:test)
function test_promote_to_custom_on_change(logger as Test.Logger) as Lang.Boolean {
    // Purpose: modifying a built-in profile should promote the model to a custom profile id.
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    // Apply a built-in first
    model.applyProfile(RugbyMatchProfiles.getBuiltInProfile("7s"), false);
    if (model.matchProfileId == "custom") { logger.error("unexpectedly already custom"); return false; }

    model.setHalfDuration(999);
    if (model.matchProfileId != "custom") { logger.error("matchProfileId not promoted to custom"); return false; }
    var stored = Storage.getValue(STORAGE_KEY_MATCH_PROFILE_ID);
    if (stored != "custom") { logger.error("matchProfileId not written to Storage"); return false; }

    return true;
}

(:test)
function test_usesSevens_and_durations(logger as Test.Logger) as Lang.Boolean {
    // Purpose: verify sevens detection and yellow/red durations.
    var m = new RugbyGameModel();
    m.initialize();

    // Force sevens
    m.setFormatFamily(true);
    if (!m.usesSevensCardRules()) { logger.error("setFormatFamily(true) did not mark sevens"); return false; }
    if (m.getYellowCardDuration() != 120) { logger.error("expected 120s yellow for sevens"); return false; }

    // Force non-sevens
    m.setFormatFamily(false);
    if (m.usesSevensCardRules()) { logger.error("setFormatFamily(false) still uses sevens rules"); return false; }
    if (m.getYellowCardDuration() != 600) { logger.error("expected 600s yellow for non-sevens"); return false; }
    if (m.getRedCardDuration() != 1200) { logger.error("expected 1200s red duration for non-sevens"); return false; }

    // Even if is7s false, a halfDuration of 420 must be considered sevens rules
    m.halfDuration = 420;
    if (!m.usesSevensCardRules()) { logger.error("halfDuration==420 did not trigger sevens rules"); return false; }

    return true;
}

(:test)
function test_custom_profile_label_intent(logger as Test.Logger) as Lang.Boolean {
    // Purpose: intended feature — custom profile should preserve user-provided label.
    // NOTE: current implementation may not persist label; this test encodes the expectation.
    clearCustomStorage();
    var custom = RugbyMatchProfiles.withTeamLabelMode(
        RugbyMatchProfiles.createProfile("custom", "MyCoolVariant", false, 1500, 40, 50, 60, true, false),
        RugbyTeamIdentitySupport.getDefaultLabelMode()
    );
    RugbyMatchProfiles.storeCustomProfile(custom);
    var s = MatchProfileEntry.fromDict(RugbyMatchProfiles.getStoredCustomProfile());
    return s != null && s.label == "MyCoolVariant";
}

(:test)
function test_match_format_label_prefers_live_rules_over_stale_profile_label(logger as Test.Logger) as Lang.Boolean {
    var customLike7s = RugbyMatchProfiles.withTeamLabelMode(
        RugbyMatchProfiles.createProfile("custom", "Rugby 15s", true, 420, 30, 30, 60, true, false),
        RugbyTeamIdentitySupport.getDefaultLabelMode()
    );
    if (RugbySettingsSupport.getMatchFormatLabel(customLike7s) != "7s") {
        logger.error("custom-like 7s rules should render as 7s");
        return false;
    }

    var customLikeU19 = RugbyMatchProfiles.withTeamLabelMode(
        RugbyMatchProfiles.createProfile("custom", "Rugby 15s", false, 2100, 90, 60, 60, true, false),
        RugbyTeamIdentitySupport.getDefaultLabelMode()
    );
    if (RugbySettingsSupport.getMatchFormatLabel(customLikeU19) != "U19s") {
        logger.error("custom-like U19 rules should render as U19s");
        return false;
    }

    var customLike15s = RugbyMatchProfiles.withTeamLabelMode(
        RugbyMatchProfiles.createProfile("custom", "Custom", false, 2400, 75, 60, 60, true, false),
        TEAM_LABEL_MODE_RED_BLUE
    );
    if (RugbySettingsSupport.getMatchFormatLabel(customLike15s) != "15s") {
        logger.error("15s half length should still render as 15s after related custom edits");
        return false;
    }

    return true;
}

(:test)
function test_setTeamLabelMode_promotes_to_custom_and_persists(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    var model = new RugbyGameModel();
    model.initialize();

    model.applyProfile(RugbyMatchProfiles.getBuiltInProfile("15s"), false);
    model.setTeamLabelMode(TEAM_LABEL_MODE_VARSITY_JV);

    if (model.matchProfileId != "custom") { logger.error("team label mode should promote to custom"); return false; }
    if (model.teamLabelMode != TEAM_LABEL_MODE_VARSITY_JV) { logger.error("model teamLabelMode mismatch"); return false; }

    var stored = MatchProfileEntry.fromDict(RugbyMatchProfiles.getStoredCustomProfile());
    return stored != null && stored.teamLabelMode == TEAM_LABEL_MODE_VARSITY_JV;
}
