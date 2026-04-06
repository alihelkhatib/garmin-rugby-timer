using Toybox.Lang;

/**
 * Typed adapter for the persisted/runtime match profile dictionary shape.
 *
 * Purpose: keep profile field access and normalization in one place while the
 * storage format remains backward-compatible and dictionary-based.
 */
class MatchProfileEntry {
    var id;
    var label;
    var is7s;
    var halfDuration;
    var conversionTime;
    var kickoffTime;
    var penaltyKickTime;
    var useConversionTimer;
    var usePenaltyTimer;
    var teamLabelMode;

    static function fromDict(profile) {
        if (!(profile instanceof Lang.Dictionary)) {
            return null;
        }
        var entry = new MatchProfileEntry();
        entry.id = profile["id"];
        entry.label = profile["label"];
        entry.is7s = profile["is7s"] == true;
        entry.halfDuration = profile["halfDuration"];
        entry.conversionTime = profile["conversionTime"];
        entry.kickoffTime = profile["kickoffTime"];
        entry.penaltyKickTime = profile["penaltyKickTime"];
        entry.useConversionTimer = profile["useConversionTimer"] == true;
        entry.usePenaltyTimer = profile["usePenaltyTimer"] == true;
        entry.teamLabelMode = RugbyTeamIdentitySupport.normalizeLabelMode(profile["teamLabelMode"]);
        return entry;
    }

    static function create(id, label, is7s, halfDuration, conversionTime, kickoffTime, penaltyKickTime, useConversionTimer, usePenaltyTimer) {
        var entry = new MatchProfileEntry();
        entry.id = id;
        entry.label = label;
        entry.is7s = is7s == true;
        entry.halfDuration = halfDuration;
        entry.conversionTime = conversionTime;
        entry.kickoffTime = kickoffTime;
        entry.penaltyKickTime = penaltyKickTime;
        entry.useConversionTimer = useConversionTimer == true;
        entry.usePenaltyTimer = usePenaltyTimer == true;
        entry.teamLabelMode = RugbyTeamIdentitySupport.getDefaultLabelMode();
        return entry;
    }

    function toDict() {
        return {
            "id" => id,
            "label" => label,
            "is7s" => is7s == true,
            "halfDuration" => halfDuration,
            "conversionTime" => conversionTime,
            "kickoffTime" => kickoffTime,
            "penaltyKickTime" => penaltyKickTime,
            "useConversionTimer" => useConversionTimer == true,
            "usePenaltyTimer" => usePenaltyTimer == true,
            "teamLabelMode" => RugbyTeamIdentitySupport.normalizeLabelMode(teamLabelMode)
        };
    }
}
