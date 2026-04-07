using Toybox.Test;
using Toybox.Lang;

/*
Unit tests for small typed wrappers introduced during warning reduction.

Purpose: ensure profile, score-event, and card-entry adapters preserve the
legacy dictionary shapes expected by the rest of the app.
*/
(:test)
function test_matchProfileEntry_roundtrip(logger as Test.Logger) as Lang.Boolean {
    var raw = RugbyMatchProfiles.withTeamLabelMode(
        RugbyMatchProfiles.createProfile("custom", "League X", true, 600, 45, 30, 60, false, true),
        TEAM_LABEL_MODE_LIGHT_DARK
    );
    var entry = MatchProfileEntry.fromDict(raw);
    if (entry == null) { logger.error("MatchProfileEntry.fromDict returned null"); return false; }
    if (entry.label != "League X") { logger.error("label mismatch"); return false; }
    var roundtrip = MatchProfileEntry.fromDict(entry.toDict());
    if (roundtrip == null) { logger.error("roundtrip profile missing"); return false; }
    return roundtrip.halfDuration == 600
        && roundtrip.usePenaltyTimer == true
        && roundtrip.teamLabelMode == TEAM_LABEL_MODE_LIGHT_DARK;
}

(:test)
function test_scoreEvent_roundtrip(logger as Test.Logger) as Lang.Boolean {
    var raw = ScoreEvent.create(:penalty_try, true).toDict() as Lang.Dictionary;
    if (raw["type"] != "penalty_try") {
        logger.error("ScoreEvent should persist string type keys");
        return false;
    }
    var entry = ScoreEvent.fromDict(raw);
    if (entry == null) { logger.error("ScoreEvent.fromDict returned null"); return false; }
    return entry.isType(:penalty_try) && entry.isHome == true;
}

(:test)
function test_scoreEvent_accepts_legacy_symbol_payload(logger as Test.Logger) as Lang.Boolean {
    var entry = ScoreEvent.fromDict({
        :type => :drop,
        :home => false
    });
    if (entry == null) { logger.error("legacy ScoreEvent payload should still restore"); return false; }
    return entry.isType(:drop) && entry.isHome == false;
}

(:test)
function test_cardEntry_roundtrip_and_invalid_input(logger as Test.Logger) as Lang.Boolean {
    var raw = CardEntry.createFromStartTime(100, 600, "Y1", 1).toDict();
    var entry = CardEntry.fromDict(raw);
    if (entry == null) { logger.error("CardEntry.fromDict returned null"); return false; }
    if (entry.cardId != 1 || entry.label != "Y1") { logger.error("CardEntry field mismatch"); return false; }
    return CardEntry.fromDict("bad") == null;
}
