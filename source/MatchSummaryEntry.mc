using Toybox.Lang;

/**
 * Typed adapter for the persisted `lastGameSummary` payload.
 *
 * Purpose: keep finalized match-summary storage explicit so persistence code
 * and tests do not depend on repeated raw dictionary access.
 */
class MatchSummaryEntry {
    var homeScore;
    var awayScore;
    var homeTries;
    var awayTries;
    var halfNumber;
    var elapsedTime;
    var countdownRemaining;
    var yellowHomeTimes;
    var yellowAwayTimes;
    var redHomeActive;
    var redAwayActive;
    var redHomePermanent;
    var redAwayPermanent;
    var yellowHomeTotal;
    var yellowAwayTotal;
    var redHomeTotal;
    var redAwayTotal;
    var eventLog;

    static function fromDict(raw) {
        if (!(raw instanceof Lang.Dictionary)) {
            return null;
        }
        var dict = raw as Lang.Dictionary;
        var entry = new MatchSummaryEntry();
        entry.homeScore = dict["homeScore"];
        entry.awayScore = dict["awayScore"];
        entry.homeTries = dict["homeTries"];
        entry.awayTries = dict["awayTries"];
        entry.halfNumber = dict["halfNumber"];
        entry.elapsedTime = dict["elapsedTime"];
        entry.countdownRemaining = dict["countdownRemaining"];
        entry.yellowHomeTimes = dict["yellowHomeTimes"];
        entry.yellowAwayTimes = dict["yellowAwayTimes"];
        entry.redHomeActive = dict["redHomeActive"];
        entry.redAwayActive = dict["redAwayActive"];
        entry.redHomePermanent = dict["redHomePermanent"];
        entry.redAwayPermanent = dict["redAwayPermanent"];
        entry.yellowHomeTotal = dict["yellowHomeTotal"];
        entry.yellowAwayTotal = dict["yellowAwayTotal"];
        entry.redHomeTotal = dict["redHomeTotal"];
        entry.redAwayTotal = dict["redAwayTotal"];
        entry.eventLog = dict["eventLog"];
        return entry;
    }

    function toDict() {
        var dict = {
            "homeScore" => homeScore,
            "awayScore" => awayScore,
            "homeTries" => homeTries,
            "awayTries" => awayTries,
            "halfNumber" => halfNumber,
            "elapsedTime" => elapsedTime,
            "countdownRemaining" => countdownRemaining,
            "yellowHomeTimes" => yellowHomeTimes,
            "yellowAwayTimes" => yellowAwayTimes,
            "redHomeActive" => redHomeActive,
            "redAwayActive" => redAwayActive,
            "redHomePermanent" => redHomePermanent,
            "redAwayPermanent" => redAwayPermanent,
            "yellowHomeTotal" => yellowHomeTotal,
            "yellowAwayTotal" => yellowAwayTotal,
            "redHomeTotal" => redHomeTotal,
            "redAwayTotal" => redAwayTotal
        };
        if (eventLog != null) {
            dict["eventLog"] = eventLog;
        }
        return dict;
    }
}
