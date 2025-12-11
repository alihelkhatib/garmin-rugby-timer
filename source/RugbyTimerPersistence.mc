using Toybox.Application.Storage;
using Toybox.Lang;

class RugbyTimerPersistence {
    static function saveState(model) {
        var snapshot = {
            "homeScore" => model.homeScore,
            "awayScore" => model.awayScore,
            "homeTries" => model.homeTries,
            "awayTries" => model.awayTries,
            "halfNumber" => model.halfNumber,
            "gameTime" => model.gameTime,
            "elapsedTime" => model.elapsedTime,
            "countdownRemaining" => model.countdownRemaining,
            "countdownSeconds" => model.countdownSeconds,
            "gameState" => model.gameState,
            "is7s" => model.is7s,
            "countdownTimer" => model.countdownTimer,
            "conversionTime7s" => model.conversionTime7s,
            "conversionTime15s" => model.conversionTime15s,
            "penaltyKickTime" => model.penaltyKickTime,
            "useConversionTimer" => model.useConversionTimer,
            "usePenaltyTimer" => model.usePenaltyTimer,
            "conversionTeam" => model.conversionTeam,
            "yellowHomeTimes" => model.yellowHomeTimes,
            "yellowAwayTimes" => model.yellowAwayTimes,
            "yellowHomeLabelCounter" => model.yellowHomeLabelCounter,
            "yellowAwayLabelCounter" => model.yellowAwayLabelCounter,
            "yellowHomeTotal" => model.yellowHomeTotal,
            "yellowAwayTotal" => model.yellowAwayTotal,
            "redHome" => model.redHome,
            "redAway" => model.redAway,
            "redHomePermanent" => model.redHomePermanent,
            "redAwayPermanent" => model.redAwayPermanent
        };
        Storage.setValue("gameStateData", snapshot);
    }

    static function finalizeGameData(model) {
        var summary = {
            "homeScore" => model.homeScore,
            "awayScore" => model.awayScore,
            "homeTries" => model.homeTries,
            "awayTries" => model.awayTries,
            "halfNumber" => model.halfNumber,
            "elapsedTime" => model.elapsedTime,
            "countdownRemaining" => model.countdownRemaining,
            "yellowHomeTimes" => model.yellowHomeTimes,
            "yellowAwayTimes" => model.yellowAwayTimes,
            "redHome" => model.redHome,
            "redAway" => model.redAway,
            "redHomePermanent" => model.redHomePermanent,
            "redAwayPermanent" => model.redAwayPermanent
        };
        summary["yellowHomeTotal"] = model.yellowHomeTotal;
        summary["yellowAwayTotal"] = model.yellowAwayTotal;
        summary["redHomeTotal"] = model.redHomeTotal;
        summary["redAwayTotal"] = model.redAwayTotal;
        var eventLogText = RugbyTimerEventLog.buildEventLogText(model);
        if (eventLogText.length() > 0) {
            summary["eventLog"] = eventLogText;
        }
        Storage.setValue("lastGameSummary", summary);
    }

    static function loadSavedState(model) {
        var data = Storage.getValue("gameStateData") as Lang.Dictionary;
        if (data != null) {
            try {
                model.homeScore = data["homeScore"];
                model.awayScore = data["awayScore"];
                model.homeTries = data["homeTries"];
                model.awayTries = data["awayTries"];
                model.halfNumber = data["halfNumber"];
                model.gameTime = data["gameTime"];
                model.elapsedTime = data["elapsedTime"];
                model.countdownRemaining = data["countdownRemaining"];
                model.countdownSeconds = data["countdownSeconds"];
                model.gameState = data["gameState"];
                model.is7s = data["is7s"];
                model.countdownTimer = data["countdownTimer"];
                model.conversionTime7s = data["conversionTime7s"];
                model.conversionTime15s = data["conversionTime1s"];
                model.penaltyKickTime = data["penaltyKickTime"];
                model.useConversionTimer = data["useConversionTimer"];
                model.usePenaltyTimer = data["usePenaltyTimer"];
                model.conversionTeam = data["conversionTeam"];
                var yHomeArr = data["yellowHomeTimes"];
                if (yHomeArr != null) {
                    model.yellowHomeTimes = RugbyTimerCards.normalizeYellowTimers(model, yHomeArr, true);
                } else {
                    model.yellowHomeTimes = [];
                }
                model.yellowHomeLabelCounter = RugbyTimerCards.computeYellowLabelCounter(model.yellowHomeTimes);
                var savedHomeLabelCounter = data["yellowHomeLabelCounter"];
                if (savedHomeLabelCounter != null && savedHomeLabelCounter > model.yellowHomeLabelCounter) {
                    model.yellowHomeLabelCounter = savedHomeLabelCounter;
                }
                var yAwayArr = data["yellowAwayTimes"];
                if (yAwayArr != null) {
                    model.yellowAwayTimes = RugbyTimerCards.normalizeYellowTimers(model, yAwayArr, false);
                } else {
                    model.yellowAwayTimes = [];
                }
                model.yellowAwayLabelCounter = RugbyTimerCards.computeYellowLabelCounter(model.yellowAwayTimes);
                var savedAwayLabelCounter = data["yellowAwayLabelCounter"];
                if (savedAwayLabelCounter != null && savedAwayLabelCounter > model.yellowAwayLabelCounter) {
                    model.yellowAwayLabelCounter = savedAwayLabelCounter;
                }
                model.redHome = data["redHome"];
                if (model.redHome == null) { model.redHome = 0; }
                model.redAway = data["redAway"];
                if (model.redAway == null) { model.redAway = 0; }
                model.redHomePermanent = data["redHomePermanent"];
                if (model.redHomePermanent == null) { model.redHomePermanent = false; }
                model.redAwayPermanent = data["redAwayPermanent"];
                if (model.redAwayPermanent == null) { model.redAwayPermanent = false; }
                model.yellowHomeTotal = data["yellowHomeTotal"];
                if (model.yellowHomeTotal == null) { model.yellowHomeTotal = 0; }
                model.yellowAwayTotal = data["yellowAwayTotal"];
                if (model.yellowAwayTotal == null) { model.yellowAwayTotal = 0; }
                model.redHomeTotal = data["redHomeTotal"];
                if (model.redHomeTotal == null) { model.redHomeTotal = 0; }
                model.redAwayTotal = data["redAwayTotal"];
                if (model.redAwayTotal == null) { model.redAwayTotal = 0; }
            } catch (ex) {
                // ignore malformed state
            }
        }
        if (model.yellowHomeTimes == null) {
            model.yellowHomeTimes = [];
        }
        if (model.yellowAwayTimes == null) {
            model.yellowAwayTimes = [];
        }
    }
}
