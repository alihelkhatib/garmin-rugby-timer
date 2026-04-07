using Toybox.System;
using Toybox.Lang;
using Toybox.Test;
using Toybox.Application.Storage;

/*
Tests for RugbyMatchProfiles storage and migration logic.
Each test includes a short purpose line explaining what requirement it verifies.
*/

// Purpose: verify storing and retrieving a custom profile persists halfDuration and is7s.
(:test)
function test_store_and_retrieve_custom_profile(logger as Test.Logger) as Lang.Boolean {
    // Save previous values to restore after test (best-effort)
    var prevHalf = Storage.getValue("customHalfDuration");
    var prevIs7s = Storage.getValue("customProfileIs7s");

    // Ensure a clean slate
    Storage.setValue("customHalfDuration", null);
    Storage.setValue("customProfileIs7s", null);

    var profile = RugbyMatchProfiles.withTeamLabelMode(
        RugbyMatchProfiles.createProfile("custom", "Custom", true, 420, 30, 30, 60, true, false),
        RugbyTeamIdentitySupport.getDefaultLabelMode()
    );
    RugbyMatchProfiles.storeCustomProfile(profile);

    var stored = MatchProfileEntry.fromDict(RugbyMatchProfiles.getStoredCustomProfile());
    if (stored == null) { logger.error("stored profile missing"); return false; }
    logger.debug("stored halfDuration -> " + stored.halfDuration.toString());

    // Restore previous values
    Storage.setValue("customHalfDuration", prevHalf);
    Storage.setValue("customProfileIs7s", prevIs7s);

    return stored.halfDuration == 420 && stored.is7s == true;
}

// Purpose: verify legacy migration falls back to defaults and returns a built-in profile id when no legacy keys exist.
(:test)
function test_migrateLegacyProfile_defaults(logger as Test.Logger) as Lang.Boolean {
    // Clear legacy keys so migration uses defaults
    Storage.setValue("rugby7s", null);
    Storage.setValue("halfDuration7s", null);
    Storage.setValue("halfDuration15s", null);
    Storage.setValue("countdownTimer", null);
    Storage.setValue("conversionTime7s", null);
    Storage.setValue("conversionTime15s", null);
    Storage.setValue("penaltyKickTime", null);
    Storage.setValue("useConversionTimer", null);
    Storage.setValue("usePenaltyTimer", null);
    Storage.setValue("matchProfileId", null);

    var inferred = RugbyMatchProfiles.migrateLegacyProfile();
    logger.debug("migrateLegacyProfile -> " + inferred);

    return inferred == "15s";
}

// Purpose: verify the explicitly stored profile id is respected on the next model initialization.
(:test)
function test_model_initialize_restores_stored_profile_id(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    Storage.setValue(STORAGE_KEY_MATCH_PROFILE_ID, "u19");

    var model = new RugbyGameModel();
    model.initialize();

    return model.matchProfileId == "u19" && model.halfDuration == 2100;
}

// Purpose: verify an invalid stored custom profile falls back to a safe non-zero preset duration.
(:test)
function test_stored_custom_profile_invalid_zero_halfDuration_falls_back_safely(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    Storage.setValue(STORAGE_KEY_MATCH_PROFILE_ID, "custom");
    Storage.setValue(STORAGE_KEY_CUSTOM_PROFILE_LABEL, "Custom");
    Storage.setValue(STORAGE_KEY_CUSTOM_PROFILE_IS_7S, false);
    Storage.setValue(STORAGE_KEY_CUSTOM_HALF_DURATION, 0);
    Storage.setValue(STORAGE_KEY_CUSTOM_CONVERSION_TIME, -1);
    Storage.setValue(STORAGE_KEY_CUSTOM_KICKOFF_TIME, -1);
    Storage.setValue(STORAGE_KEY_CUSTOM_PENALTY_KICK_TIME, -1);

    var stored = MatchProfileEntry.fromDict(RugbyMatchProfiles.getStoredCustomProfile());
    if (stored == null) {
        logger.error("stored custom profile missing");
        return false;
    }
    if (stored.halfDuration != 2400) {
        logger.error("invalid custom half duration should fall back to 15s default");
        return false;
    }
    if (stored.conversionTime != 90 || stored.kickoffTime != 60 || stored.penaltyKickTime != 60) {
        logger.error("invalid custom timers should fall back to safe defaults");
        return false;
    }
    return stored.label == "Custom";
}
