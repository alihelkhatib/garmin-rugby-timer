using Toybox.Test;
using Toybox.Lang;

/*
Unit tests for small typed wrappers introduced during warning reduction.

Purpose: ensure profile, score-event, and card-entry adapters preserve the
legacy dictionary shapes expected by the rest of the app.
*/
(:test)
function test_matchProfileEntry_roundtrip(logger as Test.Logger) as Lang.Boolean {
    var raw = RugbyMatchProfiles.createProfile("custom", "League X", true, 600, 45, 30, 60, false, true);
    var entry = MatchProfileEntry.fromDict(raw);
    if (entry == null) { logger.error("MatchProfileEntry.fromDict returned null"); return false; }
    if (entry.label != "League X") { logger.error("label mismatch"); return false; }
    var roundtrip = MatchProfileEntry.fromDict(entry.toDict());
    if (roundtrip == null) { logger.error("roundtrip profile missing"); return false; }
    return roundtrip.halfDuration == 600 && roundtrip.usePenaltyTimer == true;
}

(:test)
function test_scoreEvent_roundtrip(logger as Test.Logger) as Lang.Boolean {
    var raw = RugbyScoringService.createStoredEvent(:penalty_try, true);
    return RugbyScoringService.getStoredEventType(raw) == "penalty_try"
        && RugbyScoringService.isStoredEventHome(raw) == true;
}

(:test)
function test_scoreEvent_legacy_symbol_payload_is_supported(logger as Test.Logger) as Lang.Boolean {
    var legacy = {
        :type => :penalty_try,
        :home => true
    };
    return RugbyScoringService.getStoredEventType(legacy) == "penalty_try"
        && RugbyScoringService.isStoredEventHome(legacy) == true;
}

(:test)
function test_cardEntry_roundtrip_and_invalid_input(logger as Test.Logger) as Lang.Boolean {
    var raw = CardEntry.createFromStartTime(100, 600, "Y1", 1).toDict();
    var entry = CardEntry.fromDict(raw);
    if (entry == null) { logger.error("CardEntry.fromDict returned null"); return false; }
    if (entry.cardId != 1 || entry.label != "Y1") { logger.error("CardEntry field mismatch"); return false; }
    return CardEntry.fromDict("bad") == null;
}
