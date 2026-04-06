using Toybox.Test;
using Toybox.Lang;

/*
Unit tests for team-identity helpers and preset-backed event wording.

Purpose: verify label preset resolution and team-specific event strings without
requiring UI interaction or device-specific text entry.
*/
(:test)
function test_teamIdentitySupport_normalizes_invalid_mode(logger as Test.Logger) as Lang.Boolean {
    return RugbyTeamIdentitySupport.normalizeLabelMode("invalid") == TEAM_LABEL_MODE_HOME_AWAY;
}

(:test)
function test_teamIdentitySupport_resolves_labels_for_preset(logger as Test.Logger) as Lang.Boolean {
    return RugbyTeamIdentitySupport.getHomeLabel(TEAM_LABEL_MODE_FIRST_SECOND_XV) == "1st XV"
        && RugbyTeamIdentitySupport.getAwayLabel(TEAM_LABEL_MODE_FIRST_SECOND_XV) == "2nd XV";
}

(:test)
function test_teamIdentitySupport_builds_event_description_from_model(logger as Test.Logger) as Lang.Boolean {
    var model = new RugbyGameModel();
    model.initialize();
    model.teamLabelMode = TEAM_LABEL_MODE_RED_BLUE;
    return RugbyTeamIdentitySupport.buildEventDescription(model, false, "Penalty Goal") == "Blue Penalty Goal";
}

(:test)
function test_teamIdentitySupport_compact_scoreBand_labels(logger as Test.Logger) as Lang.Boolean {
    return RugbyTeamIdentitySupport.getScoreBandLabel(TEAM_LABEL_MODE_FIRST_SECOND_XV, true, true) == "1st"
        && RugbyTeamIdentitySupport.getScoreBandLabel(TEAM_LABEL_MODE_VARSITY_JV, false, true) == "JV";
}
