using Toybox.Application.Storage;

/**
 * Central source of truth for built-in match presets plus the editable custom profile.
 *
 * Purpose: define built-in rulesets, custom-profile persistence, and legacy
 * storage migration in one place so settings and model code share one profile source.
 */
class RugbyMatchProfiles {
    static function createProfile(id, label, is7s, halfDuration, conversionTime, kickoffTime, penaltyKickTime, useConversionTimer, usePenaltyTimer) {
        return MatchProfileEntry.create(
            id,
            label,
            is7s,
            halfDuration,
            conversionTime,
            kickoffTime,
            penaltyKickTime,
            useConversionTimer,
            usePenaltyTimer
        ).toDict();
    }

    static function withTeamLabelMode(profile, teamLabelMode) {
        var entry = MatchProfileEntry.fromDict(profile);
        if (entry == null) {
            return profile;
        }
        entry.teamLabelMode = RugbyTeamIdentitySupport.normalizeLabelMode(teamLabelMode);
        return entry.toDict();
    }

    static function getBuiltInProfile(profileId) {
        if (profileId == "7s") {
            return RugbyMatchProfiles.createProfile("7s", "Rugby 7s", true, 420, 30, 30, 60, true, false);
        } else if (profileId == "10s") {
            return RugbyMatchProfiles.createProfile("10s", "Rugby 10s", false, 600, 90, 60, 60, true, false);
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
        var profileId = Storage.getValue(STORAGE_KEY_MATCH_PROFILE_ID);
        if (profileId != null) {
            return profileId;
        }
        return RugbyMatchProfiles.migrateLegacyProfile();
    }

    static function hasStoredCustomProfile() {
        return Storage.getValue(STORAGE_KEY_CUSTOM_HALF_DURATION) != null;
    }

    static function getStoredCustomProfile() {
        var fallback = MatchProfileEntry.fromDict(RugbyMatchProfiles.getBuiltInProfile("15s"));
        if (fallback == null) {
            fallback = MatchProfileEntry.create("15s", "Rugby 15s", false, 2400, 90, 60, 60, true, false);
        }
        var label = Storage.getValue(STORAGE_KEY_CUSTOM_PROFILE_LABEL);
        if (label == null) { label = "Custom"; }
        var is7s = Storage.getValue(STORAGE_KEY_CUSTOM_PROFILE_IS_7S);
        if (is7s == null) { is7s = fallback.is7s; }
        var halfDuration = Storage.getValue(STORAGE_KEY_CUSTOM_HALF_DURATION);
        if (halfDuration == null) { halfDuration = fallback.halfDuration; }
        var conversionTime = Storage.getValue(STORAGE_KEY_CUSTOM_CONVERSION_TIME);
        if (conversionTime == null) { conversionTime = fallback.conversionTime; }
        var kickoffTime = Storage.getValue(STORAGE_KEY_CUSTOM_KICKOFF_TIME);
        if (kickoffTime == null) { kickoffTime = fallback.kickoffTime; }
        var penaltyKickTime = Storage.getValue(STORAGE_KEY_CUSTOM_PENALTY_KICK_TIME);
        if (penaltyKickTime == null) { penaltyKickTime = fallback.penaltyKickTime; }
        var useConversionTimer = Storage.getValue(STORAGE_KEY_CUSTOM_USE_CONVERSION_TIMER);
        if (useConversionTimer == null) { useConversionTimer = fallback.useConversionTimer; }
        var usePenaltyTimer = Storage.getValue(STORAGE_KEY_CUSTOM_USE_PENALTY_TIMER);
        if (usePenaltyTimer == null) { usePenaltyTimer = fallback.usePenaltyTimer; }
        var teamLabelMode = Storage.getValue(STORAGE_KEY_CUSTOM_TEAM_LABEL_MODE);
        if (teamLabelMode == null) { teamLabelMode = fallback.teamLabelMode; }

        return RugbyMatchProfiles.withTeamLabelMode(RugbyMatchProfiles.createProfile(
            "custom",
            label,
            is7s,
            halfDuration,
            conversionTime,
            kickoffTime,
            penaltyKickTime,
            useConversionTimer,
            usePenaltyTimer
        ), teamLabelMode);
    }

    static function storeCustomProfile(profile) {
        var entry = MatchProfileEntry.fromDict(profile);
        if (entry == null) {
            return;
        }
        var label = entry.label;
        if (label == null) { label = "Custom"; }
        Storage.setValue(STORAGE_KEY_CUSTOM_PROFILE_LABEL, label);
        Storage.setValue(STORAGE_KEY_CUSTOM_PROFILE_IS_7S, entry.is7s);
        Storage.setValue(STORAGE_KEY_CUSTOM_HALF_DURATION, entry.halfDuration);
        Storage.setValue(STORAGE_KEY_CUSTOM_CONVERSION_TIME, entry.conversionTime);
        Storage.setValue(STORAGE_KEY_CUSTOM_KICKOFF_TIME, entry.kickoffTime);
        Storage.setValue(STORAGE_KEY_CUSTOM_PENALTY_KICK_TIME, entry.penaltyKickTime);
        Storage.setValue(STORAGE_KEY_CUSTOM_USE_CONVERSION_TIMER, entry.useConversionTimer);
        Storage.setValue(STORAGE_KEY_CUSTOM_USE_PENALTY_TIMER, entry.usePenaltyTimer);
        Storage.setValue(STORAGE_KEY_CUSTOM_TEAM_LABEL_MODE, RugbyTeamIdentitySupport.normalizeLabelMode(entry.teamLabelMode));
    }

    static function getProfileLabel(profileId) {
        var entry = MatchProfileEntry.fromDict(RugbyMatchProfiles.getProfile(profileId));
        return entry != null ? entry.label : "";
    }

    static function getFormatLabel(is7s) {
        return is7s ? "7s" : "15s";
    }

    static function getMatchFormatIds() {
        return ["7s", "10s", "15s", "u19"];
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
        var entry = MatchProfileEntry.fromDict(profile);
        if (entry == null) {
            return false;
        }
        return entry.is7s == is7s
            && entry.halfDuration == halfDuration
            && entry.conversionTime == conversionTime
            && entry.kickoffTime == kickoffTime
            && entry.penaltyKickTime == penaltyKickTime
            && entry.useConversionTimer == useConversionTimer
            && entry.usePenaltyTimer == usePenaltyTimer;
    }

    static function migrateLegacyProfile() {
        var is7s = Storage.getValue(STORAGE_KEY_LEGACY_RUGBY_7S);
        if (is7s == null) { is7s = false; }

        var typeKey = is7s ? STORAGE_KEY_LEGACY_HALF_DURATION_7S : STORAGE_KEY_LEGACY_HALF_DURATION_15S;
        var halfDuration = Storage.getValue(typeKey);
        if (halfDuration == null) { halfDuration = Storage.getValue(STORAGE_KEY_LEGACY_COUNTDOWN_TIMER); }
        if (halfDuration == null) {
            halfDuration = is7s ? 420 : 2400;
        }

        var conversionTime = Storage.getValue(is7s ? STORAGE_KEY_LEGACY_CONVERSION_TIME_7S : STORAGE_KEY_LEGACY_CONVERSION_TIME_15S);
        if (conversionTime == null) {
            conversionTime = is7s ? 30 : 90;
        }

        var penaltyKickTime = Storage.getValue(STORAGE_KEY_LEGACY_PENALTY_KICK_TIME);
        if (penaltyKickTime == null) { penaltyKickTime = 60; }

        var useConversionTimer = Storage.getValue(STORAGE_KEY_LEGACY_USE_CONVERSION_TIMER);
        if (useConversionTimer == null) { useConversionTimer = true; }

        var usePenaltyTimer = Storage.getValue(STORAGE_KEY_LEGACY_USE_PENALTY_TIMER);
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

        Storage.setValue(STORAGE_KEY_MATCH_PROFILE_ID, inferredProfileId);
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
