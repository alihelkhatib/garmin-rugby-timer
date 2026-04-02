using Toybox.Application.Storage;

/**
 * Central source of truth for built-in match presets plus the editable custom profile.
 */
class RugbyMatchProfiles {
    static function createProfile(id, label, is7s, halfDuration, conversionTime, kickoffTime, penaltyKickTime, useConversionTimer, usePenaltyTimer) {
        return {
            "id" => id,
            "label" => label,
            "is7s" => is7s,
            "halfDuration" => halfDuration,
            "conversionTime" => conversionTime,
            "kickoffTime" => kickoffTime,
            "penaltyKickTime" => penaltyKickTime,
            "useConversionTimer" => useConversionTimer,
            "usePenaltyTimer" => usePenaltyTimer
        };
    }

    static function getBuiltInProfile(profileId) {
        if (profileId == "7s") {
            return RugbyMatchProfiles.createProfile("7s", "Rugby 7s", true, 420, 30, 30, 60, true, false);
        } else if (profileId == "10s") {
            return RugbyMatchProfiles.createProfile("10s", "Rugby 10s", false, 2400, 90, 60, 60, true, false);
        } else if (profileId == "u19") {
            return RugbyMatchProfiles.createProfile("u19", "U19", false, 2100, 90, 60, 60, true, false);
        }
        return RugbyMatchProfiles.createProfile("15s", "Rugby 15s", false, 2400, 90, 60, 60, true, false);
    }

    static function getProfile(profileId) {
        if (profileId == "custom") {
            return RugbyMatchProfiles.getStoredCustomProfile();
        }
        return RugbyMatchProfiles.getBuiltInProfile(profileId);
    }

    static function getStoredProfileId() {
        var profileId = Storage.getValue("matchProfileId");
        if (profileId != null) {
            return profileId;
        }
        return RugbyMatchProfiles.migrateLegacyProfile();
    }

    static function hasStoredCustomProfile() {
        return Storage.getValue("customHalfDuration") != null;
    }

    static function getStoredCustomProfile() {
        var fallback = RugbyMatchProfiles.getBuiltInProfile("15s");
        var is7s = Storage.getValue("customProfileIs7s");
        if (is7s == null) { is7s = fallback["is7s"]; }
        var halfDuration = Storage.getValue("customHalfDuration");
        if (halfDuration == null) { halfDuration = fallback["halfDuration"]; }
        var conversionTime = Storage.getValue("customConversionTime");
        if (conversionTime == null) { conversionTime = fallback["conversionTime"]; }
        var kickoffTime = Storage.getValue("customKickoffTime");
        if (kickoffTime == null) { kickoffTime = fallback["kickoffTime"]; }
        var penaltyKickTime = Storage.getValue("customPenaltyKickTime");
        if (penaltyKickTime == null) { penaltyKickTime = fallback["penaltyKickTime"]; }
        var useConversionTimer = Storage.getValue("customUseConversionTimer");
        if (useConversionTimer == null) { useConversionTimer = fallback["useConversionTimer"]; }
        var usePenaltyTimer = Storage.getValue("customUsePenaltyTimer");
        if (usePenaltyTimer == null) { usePenaltyTimer = fallback["usePenaltyTimer"]; }

        return RugbyMatchProfiles.createProfile(
            "custom",
            "Custom",
            is7s,
            halfDuration,
            conversionTime,
            kickoffTime,
            penaltyKickTime,
            useConversionTimer,
            usePenaltyTimer
        );
    }

    static function storeCustomProfile(profile) {
        if (profile == null) {
            return;
        }
        Storage.setValue("customProfileIs7s", profile["is7s"]);
        Storage.setValue("customHalfDuration", profile["halfDuration"]);
        Storage.setValue("customConversionTime", profile["conversionTime"]);
        Storage.setValue("customKickoffTime", profile["kickoffTime"]);
        Storage.setValue("customPenaltyKickTime", profile["penaltyKickTime"]);
        Storage.setValue("customUseConversionTimer", profile["useConversionTimer"]);
        Storage.setValue("customUsePenaltyTimer", profile["usePenaltyTimer"]);
    }

    static function getProfileLabel(profileId) {
        return RugbyMatchProfiles.getProfile(profileId)["label"];
    }

    static function getFormatLabel(is7s) {
        return is7s ? "7s-style" : "15s-style";
    }

    static function inferProfileIdFromSettings(is7s, halfDuration, conversionTime, kickoffTime, penaltyKickTime, useConversionTimer, usePenaltyTimer) {
        var builtInIds = ["7s", "10s", "15s", "u19"];
        for (var i = 0; i < builtInIds.size(); i = i + 1) {
            var profileId = builtInIds[i];
            var profile = RugbyMatchProfiles.getBuiltInProfile(profileId);
            if (RugbyMatchProfiles.matchesProfile(profile, is7s, halfDuration, conversionTime, kickoffTime, penaltyKickTime, useConversionTimer, usePenaltyTimer)) {
                return profileId;
            }
        }

        return "custom";
    }

    static function matchesProfile(profile, is7s, halfDuration, conversionTime, kickoffTime, penaltyKickTime, useConversionTimer, usePenaltyTimer) {
        return profile["is7s"] == is7s
            && profile["halfDuration"] == halfDuration
            && profile["conversionTime"] == conversionTime
            && profile["kickoffTime"] == kickoffTime
            && profile["penaltyKickTime"] == penaltyKickTime
            && profile["useConversionTimer"] == useConversionTimer
            && profile["usePenaltyTimer"] == usePenaltyTimer;
    }

    static function migrateLegacyProfile() {
        var is7s = Storage.getValue("rugby7s");
        if (is7s == null) { is7s = false; }

        var typeKey = is7s ? "halfDuration7s" : "halfDuration15s";
        var halfDuration = Storage.getValue(typeKey);
        if (halfDuration == null) { halfDuration = Storage.getValue("countdownTimer"); }
        if (halfDuration == null) {
            halfDuration = is7s ? 420 : 2400;
        }

        var conversionTime = Storage.getValue(is7s ? "conversionTime7s" : "conversionTime15s");
        if (conversionTime == null) {
            conversionTime = is7s ? 30 : 90;
        }

        var penaltyKickTime = Storage.getValue("penaltyKickTime");
        if (penaltyKickTime == null) { penaltyKickTime = 60; }

        var useConversionTimer = Storage.getValue("useConversionTimer");
        if (useConversionTimer == null) { useConversionTimer = true; }

        var usePenaltyTimer = Storage.getValue("usePenaltyTimer");
        if (usePenaltyTimer == null) { usePenaltyTimer = false; }

        var kickoffTime = is7s ? 30 : 60;
        var inferredProfileId = RugbyMatchProfiles.inferProfileIdFromSettings(
            is7s,
            halfDuration,
            conversionTime,
            kickoffTime,
            penaltyKickTime,
            useConversionTimer,
            usePenaltyTimer
        );

        Storage.setValue("matchProfileId", inferredProfileId);
        if (inferredProfileId == "custom") {
            RugbyMatchProfiles.storeCustomProfile(RugbyMatchProfiles.createProfile(
                "custom",
                "Custom",
                is7s,
                halfDuration,
                conversionTime,
                kickoffTime,
                penaltyKickTime,
                useConversionTimer,
                usePenaltyTimer
            ));
        }
        return inferredProfileId;
    }
}
