using Toybox.Lang;

/**
 * Typed adapter for the `gameStateData` storage payload.
 *
 * Purpose: keep the full persisted match-snapshot schema explicit while the
 * stored representation remains dictionary-based for backward compatibility.
 */
class PersistedGameSnapshot {
    var homeScore;
    var awayScore;
    var homeTries;
    var awayTries;
    var halfNumber;
    var gameTime;
    var suspensionTime;
    var elapsedTime;
    var countdownRemaining;
    var countdownSeconds;
    var gameState;
    var pausedState;
    var matchProfileId;
    var is7s;
    var countdownTimer;
    var conversionTime;
    var kickoffTime;
    var penaltyKickTime;
    var useConversionTimer;
    var usePenaltyTimer;
    var conversionTeam;
    var yellowHomeTimes;
    var yellowAwayTimes;
    var yellowHomeLabelCounter;
    var yellowAwayLabelCounter;
    var redHomeLabelCounter;
    var redAwayLabelCounter;
    var yellowHomeTotal;
    var yellowAwayTotal;
    var redHomeTimes;
    var redAwayTimes;
    var redHomePermanent;
    var redAwayPermanent;
    var redHomeTotal;
    var redAwayTotal;
    var homePenalties;
    var awayPenalties;
    var lastEvents;
    var eventLogEntries;
    var conversionTime7s;
    var conversionTime15s;

    static function fromDict(raw) {
        if (!(raw instanceof Lang.Dictionary)) {
            return null;
        }
        var dict = raw as Lang.Dictionary;
        var snapshot = new PersistedGameSnapshot();
        snapshot.homeScore = dict["homeScore"];
        snapshot.awayScore = dict["awayScore"];
        snapshot.homeTries = dict["homeTries"];
        snapshot.awayTries = dict["awayTries"];
        snapshot.halfNumber = dict["halfNumber"];
        snapshot.gameTime = dict["gameTime"];
        snapshot.suspensionTime = dict["suspensionTime"];
        snapshot.elapsedTime = dict["elapsedTime"];
        snapshot.countdownRemaining = dict["countdownRemaining"];
        snapshot.countdownSeconds = dict["countdownSeconds"];
        snapshot.gameState = dict["gameState"];
        snapshot.pausedState = dict["pausedState"];
        snapshot.matchProfileId = dict["matchProfileId"];
        snapshot.is7s = dict["is7s"];
        snapshot.countdownTimer = dict["countdownTimer"];
        snapshot.conversionTime = dict["conversionTime"];
        snapshot.kickoffTime = dict["kickoffTime"];
        snapshot.penaltyKickTime = dict["penaltyKickTime"];
        snapshot.useConversionTimer = dict["useConversionTimer"];
        snapshot.usePenaltyTimer = dict["usePenaltyTimer"];
        snapshot.conversionTeam = dict["conversionTeam"];
        snapshot.yellowHomeTimes = dict["yellowHomeTimes"];
        snapshot.yellowAwayTimes = dict["yellowAwayTimes"];
        snapshot.yellowHomeLabelCounter = dict["yellowHomeLabelCounter"];
        snapshot.yellowAwayLabelCounter = dict["yellowAwayLabelCounter"];
        snapshot.redHomeLabelCounter = dict["redHomeLabelCounter"];
        snapshot.redAwayLabelCounter = dict["redAwayLabelCounter"];
        snapshot.yellowHomeTotal = dict["yellowHomeTotal"];
        snapshot.yellowAwayTotal = dict["yellowAwayTotal"];
        snapshot.redHomeTimes = dict["redHomeTimes"];
        snapshot.redAwayTimes = dict["redAwayTimes"];
        snapshot.redHomePermanent = dict["redHomePermanent"];
        snapshot.redAwayPermanent = dict["redAwayPermanent"];
        snapshot.redHomeTotal = dict["redHomeTotal"];
        snapshot.redAwayTotal = dict["redAwayTotal"];
        snapshot.homePenalties = dict["homePenalties"];
        snapshot.awayPenalties = dict["awayPenalties"];
        snapshot.lastEvents = dict["lastEvents"];
        snapshot.eventLogEntries = dict["eventLogEntries"];
        snapshot.conversionTime7s = dict["conversionTime7s"];
        snapshot.conversionTime15s = dict["conversionTime15s"];
        return snapshot;
    }

    function toDict() {
        return {
            "homeScore" => homeScore,
            "awayScore" => awayScore,
            "homeTries" => homeTries,
            "awayTries" => awayTries,
            "halfNumber" => halfNumber,
            "gameTime" => gameTime,
            "suspensionTime" => suspensionTime,
            "elapsedTime" => elapsedTime,
            "countdownRemaining" => countdownRemaining,
            "countdownSeconds" => countdownSeconds,
            "gameState" => gameState,
            "pausedState" => pausedState,
            "matchProfileId" => matchProfileId,
            "is7s" => is7s,
            "countdownTimer" => countdownTimer,
            "conversionTime" => conversionTime,
            "kickoffTime" => kickoffTime,
            "penaltyKickTime" => penaltyKickTime,
            "useConversionTimer" => useConversionTimer,
            "usePenaltyTimer" => usePenaltyTimer,
            "conversionTeam" => conversionTeam,
            "yellowHomeTimes" => yellowHomeTimes,
            "yellowAwayTimes" => yellowAwayTimes,
            "yellowHomeLabelCounter" => yellowHomeLabelCounter,
            "yellowAwayLabelCounter" => yellowAwayLabelCounter,
            "redHomeLabelCounter" => redHomeLabelCounter,
            "redAwayLabelCounter" => redAwayLabelCounter,
            "yellowHomeTotal" => yellowHomeTotal,
            "yellowAwayTotal" => yellowAwayTotal,
            "redHomeTimes" => redHomeTimes,
            "redAwayTimes" => redAwayTimes,
            "redHomePermanent" => redHomePermanent,
            "redAwayPermanent" => redAwayPermanent,
            "redHomeTotal" => redHomeTotal,
            "redAwayTotal" => redAwayTotal,
            "homePenalties" => homePenalties,
            "awayPenalties" => awayPenalties,
            "lastEvents" => lastEvents,
            "eventLogEntries" => eventLogEntries
        };
    }
}
