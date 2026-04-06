using Toybox.Lang;

/**
 * Pure helper methods for settings/profile UI code.
 *
 * These functions intentionally avoid WatchUi side effects so they can be
 * unit-tested directly and reused across multiple settings files.
 */
class RugbySettingsSupport {
    static function getMatchFormatLabelForValues(is7s, halfDuration) {
        if (halfDuration == 600) { return "10s"; }
        if (halfDuration == 2100) { return "U19s"; }
        if (halfDuration == 2400) { return "15s"; }
        if (halfDuration == 420 || is7s == true) { return "7s"; }
        return "Custom";
    }

    static function getProfileEntry(profile) {
        return MatchProfileEntry.fromDict(profile);
    }

    static function getProfileLabel(profile) {
        var entry = RugbySettingsSupport.getProfileEntry(profile);
        return entry != null ? entry.label : null;
    }

    static function getFormatLabel(profile) {
        var entry = RugbySettingsSupport.getProfileEntry(profile);
        return entry != null ? RugbyMatchProfiles.getFormatLabel(entry.is7s) : null;
    }

    static function getMatchFormatLabel(profile) {
        var entry = RugbySettingsSupport.getProfileEntry(profile);
        if (entry == null) {
            return null;
        }
        return RugbySettingsSupport.getMatchFormatLabelForValues(entry.is7s, entry.halfDuration);
    }

    static function getHalfLabel(profile, menu) {
        var entry = RugbySettingsSupport.getProfileEntry(profile);
        return entry != null ? menu.formatTime(entry.halfDuration) : null;
    }

    static function getConversionLabel(profile, menu) {
        var entry = RugbySettingsSupport.getProfileEntry(profile);
        return entry != null ? menu.formatTime(entry.conversionTime) : null;
    }

    static function getPenaltyLabel(profile, menu) {
        var entry = RugbySettingsSupport.getProfileEntry(profile);
        return entry != null ? menu.formatTime(entry.penaltyKickTime) : null;
    }

    static function getOnOffLabel(enabled) {
        return enabled == true ? "On" : "Off";
    }

    static function getTeamLabelModeLabel(profile) {
        var entry = RugbySettingsSupport.getProfileEntry(profile);
        if (entry == null) {
            return RugbyTeamIdentitySupport.getLabelModeDisplayName(null);
        }
        return RugbyTeamIdentitySupport.getLabelModeDisplayName(entry.teamLabelMode);
    }

    static function resolveFormatFamily(itemId) {
        var idText = itemId != null ? itemId.toString() : "";
        if (itemId == :format_7s || idText == "format_7s" || idText == ":format_7s") {
            return true;
        }
        if (itemId == :format_15s || idText == "format_15s" || idText == ":format_15s") {
            return false;
        }
        return null;
    }

    static function resolveMatchFormatId(itemId) {
        var idText = itemId != null ? itemId.toString() : "";
        if (itemId == :match_format_7s || idText == "match_format_7s" || idText == ":match_format_7s") {
            return "7s";
        }
        if (itemId == :match_format_10s || idText == "match_format_10s" || idText == ":match_format_10s") {
            return "10s";
        }
        if (itemId == :match_format_15s || idText == "match_format_15s" || idText == ":match_format_15s") {
            return "15s";
        }
        if (itemId == :match_format_u19 || idText == "match_format_u19" || idText == ":match_format_u19") {
            return "u19";
        }
        return null;
    }

    static function resolveTeamLabelMode(itemId) {
        var idText = itemId != null ? itemId.toString() : "";
        if (itemId == :team_label_team_a_b || idText == "team_label_team_a_b" || idText == ":team_label_team_a_b") {
            return TEAM_LABEL_MODE_TEAM_A_B;
        }
        if (itemId == :team_label_light_dark || idText == "team_label_light_dark" || idText == ":team_label_light_dark") {
            return TEAM_LABEL_MODE_LIGHT_DARK;
        }
        if (itemId == :team_label_red_blue || idText == "team_label_red_blue" || idText == ":team_label_red_blue") {
            return TEAM_LABEL_MODE_RED_BLUE;
        }
        if (itemId == :team_label_first_second_xv || idText == "team_label_first_second_xv" || idText == ":team_label_first_second_xv") {
            return TEAM_LABEL_MODE_FIRST_SECOND_XV;
        }
        if (itemId == :team_label_varsity_jv || idText == "team_label_varsity_jv" || idText == ":team_label_varsity_jv") {
            return TEAM_LABEL_MODE_VARSITY_JV;
        }
        if (itemId == :team_label_sharks_blues || idText == "team_label_sharks_blues" || idText == ":team_label_sharks_blues") {
            return TEAM_LABEL_MODE_SHARKS_BLUES;
        }
        if (itemId == :team_label_a_b || idText == "team_label_a_b" || idText == ":team_label_a_b") {
            return TEAM_LABEL_MODE_A_B;
        }
        return TEAM_LABEL_MODE_HOME_AWAY;
    }

    static function resolveProfileId(itemId) {
        // Accept both Symbol and String forms because Connect IQ menu ids can
        // arrive differently across runtime paths and tests.
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

    static function clampMinutes(minutes) {
        if (minutes < 1) { return 1; }
        if (minutes > 99) { return 99; }
        return minutes;
    }

    static function getMinutesFromDigits(values) {
        if (!(values instanceof Lang.Array) || values.size() < 2) {
            return 1;
        }
        var tens = values[0];
        var units = values[1];
        if (!(tens instanceof Lang.Number) || !(units instanceof Lang.Number)) {
            return 1;
        }
        return RugbySettingsSupport.clampMinutes((tens * 10) + units);
    }

    static function getConversionSelectionSeconds(itemId) {
        if (itemId == "t60" || itemId == :t60) { return 60; }
        if (itemId == "t90" || itemId == :t90) { return 90; }
        if (itemId == "t120" || itemId == :t120) { return 120; }
        return 30;
    }

    static function getPenaltySelectionSeconds(itemId) {
        if (itemId == "p60" || itemId == :p60) { return 60; }
        if (itemId == "p90" || itemId == :p90) { return 90; }
        return 30;
    }
}
