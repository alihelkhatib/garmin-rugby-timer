const TEAM_LABEL_MODE_HOME_AWAY = "home_away";
const TEAM_LABEL_MODE_TEAM_A_B = "team_a_b";
const TEAM_LABEL_MODE_LIGHT_DARK = "light_dark";
const TEAM_LABEL_MODE_RED_BLUE = "red_blue";
const TEAM_LABEL_MODE_FIRST_SECOND_XV = "first_second_xv";
const TEAM_LABEL_MODE_VARSITY_JV = "varsity_jv";
const TEAM_LABEL_MODE_SHARKS_BLUES = "sharks_blues";
const TEAM_LABEL_MODE_A_B = "a_b";

/**
 * Shared team-identity helpers for label presets.
 *
 * Purpose: keep team-label resolution, defaults, and event-log wording in one
 * place so settings, rendering, and persistence stay consistent.
 */
class RugbyTeamIdentitySupport {
    static function getDefaultLabelMode() {
        return TEAM_LABEL_MODE_HOME_AWAY;
    }

    static function normalizeLabelMode(mode) {
        if (mode == TEAM_LABEL_MODE_TEAM_A_B || mode == TEAM_LABEL_MODE_LIGHT_DARK
                || mode == TEAM_LABEL_MODE_RED_BLUE || mode == TEAM_LABEL_MODE_FIRST_SECOND_XV
                || mode == TEAM_LABEL_MODE_VARSITY_JV || mode == TEAM_LABEL_MODE_SHARKS_BLUES
                || mode == TEAM_LABEL_MODE_A_B) {
            return mode;
        }
        return TEAM_LABEL_MODE_HOME_AWAY;
    }

    static function getLabelModeDisplayName(mode) {
        var normalized = RugbyTeamIdentitySupport.normalizeLabelMode(mode);
        if (normalized == TEAM_LABEL_MODE_TEAM_A_B) { return "Team A / Team B"; }
        if (normalized == TEAM_LABEL_MODE_LIGHT_DARK) { return "Light / Dark"; }
        if (normalized == TEAM_LABEL_MODE_RED_BLUE) { return "Red / Blue"; }
        if (normalized == TEAM_LABEL_MODE_FIRST_SECOND_XV) { return "1st XV / 2nd XV"; }
        if (normalized == TEAM_LABEL_MODE_VARSITY_JV) { return "Varsity / JV"; }
        if (normalized == TEAM_LABEL_MODE_SHARKS_BLUES) { return "Sharks / Blues"; }
        if (normalized == TEAM_LABEL_MODE_A_B) { return "A / B"; }
        return "Home / Away";
    }

    static function getHomeLabel(mode) {
        var normalized = RugbyTeamIdentitySupport.normalizeLabelMode(mode);
        if (normalized == TEAM_LABEL_MODE_TEAM_A_B) { return "Team A"; }
        if (normalized == TEAM_LABEL_MODE_LIGHT_DARK) { return "Light"; }
        if (normalized == TEAM_LABEL_MODE_RED_BLUE) { return "Red"; }
        if (normalized == TEAM_LABEL_MODE_FIRST_SECOND_XV) { return "1st XV"; }
        if (normalized == TEAM_LABEL_MODE_VARSITY_JV) { return "Varsity"; }
        if (normalized == TEAM_LABEL_MODE_SHARKS_BLUES) { return "Sharks"; }
        if (normalized == TEAM_LABEL_MODE_A_B) { return "A"; }
        return "Home";
    }

    static function getAwayLabel(mode) {
        var normalized = RugbyTeamIdentitySupport.normalizeLabelMode(mode);
        if (normalized == TEAM_LABEL_MODE_TEAM_A_B) { return "Team B"; }
        if (normalized == TEAM_LABEL_MODE_LIGHT_DARK) { return "Dark"; }
        if (normalized == TEAM_LABEL_MODE_RED_BLUE) { return "Blue"; }
        if (normalized == TEAM_LABEL_MODE_FIRST_SECOND_XV) { return "2nd XV"; }
        if (normalized == TEAM_LABEL_MODE_VARSITY_JV) { return "JV"; }
        if (normalized == TEAM_LABEL_MODE_SHARKS_BLUES) { return "Blues"; }
        if (normalized == TEAM_LABEL_MODE_A_B) { return "B"; }
        return "Away";
    }

    static function getCompactHomeLabel(mode) {
        var normalized = RugbyTeamIdentitySupport.normalizeLabelMode(mode);
        if (normalized == TEAM_LABEL_MODE_TEAM_A_B) { return "T A"; }
        if (normalized == TEAM_LABEL_MODE_LIGHT_DARK) { return "L"; }
        if (normalized == TEAM_LABEL_MODE_RED_BLUE) { return "R"; }
        if (normalized == TEAM_LABEL_MODE_FIRST_SECOND_XV) { return "1st"; }
        if (normalized == TEAM_LABEL_MODE_VARSITY_JV) { return "V"; }
        if (normalized == TEAM_LABEL_MODE_SHARKS_BLUES) { return "Shk"; }
        if (normalized == TEAM_LABEL_MODE_A_B) { return "A"; }
        return "Home";
    }

    static function getCompactAwayLabel(mode) {
        var normalized = RugbyTeamIdentitySupport.normalizeLabelMode(mode);
        if (normalized == TEAM_LABEL_MODE_TEAM_A_B) { return "T B"; }
        if (normalized == TEAM_LABEL_MODE_LIGHT_DARK) { return "D"; }
        if (normalized == TEAM_LABEL_MODE_RED_BLUE) { return "B"; }
        if (normalized == TEAM_LABEL_MODE_FIRST_SECOND_XV) { return "2nd"; }
        if (normalized == TEAM_LABEL_MODE_VARSITY_JV) { return "JV"; }
        if (normalized == TEAM_LABEL_MODE_SHARKS_BLUES) { return "Blu"; }
        if (normalized == TEAM_LABEL_MODE_A_B) { return "B"; }
        return "Away";
    }

    static function getTeamLabel(model, isHome) {
        var labelMode = RugbyTeamIdentitySupport.getDefaultLabelMode();
        if (model != null && model.teamLabelMode != null) {
            labelMode = model.teamLabelMode;
        }
        return isHome ? RugbyTeamIdentitySupport.getHomeLabel(labelMode) : RugbyTeamIdentitySupport.getAwayLabel(labelMode);
    }

    static function getScoreBandLabel(mode, isHome, compact) {
        var normalized = RugbyTeamIdentitySupport.normalizeLabelMode(mode);
        if (compact == true) {
            return isHome ? RugbyTeamIdentitySupport.getCompactHomeLabel(normalized) : RugbyTeamIdentitySupport.getCompactAwayLabel(normalized);
        }
        return isHome ? RugbyTeamIdentitySupport.getHomeLabel(normalized) : RugbyTeamIdentitySupport.getAwayLabel(normalized);
    }

    static function buildEventDescription(model, isHome, actionText) {
        var prefix = RugbyTeamIdentitySupport.getTeamLabel(model, isHome);
        if (actionText == null || actionText.length() == 0) {
            return prefix;
        }
        return prefix + " " + actionText;
    }
}
