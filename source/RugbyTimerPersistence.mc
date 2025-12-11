using Toybox.Application.Storage;
using Toybox.Lang;

class RugbyTimerPersistence {
    static function saveState(view) {
        var snapshot = {
            "homeScore" => view.homeScore,
            "awayScore" => view.awayScore,
            "homeTries" => view.homeTries,
            "awayTries" => view.awayTries,
            "halfNumber" => view.halfNumber,
            "gameTime" => view.gameTime,
            "elapsedTime" => view.elapsedTime,
            "countdownRemaining" => view.countdownRemaining,
            "countdownSeconds" => view.countdownSeconds,
            "gameState" => view.gameState,
            "is7s" => view.is7s,
            "countdownTimer" => view.countdownTimer,
            "conversionTime7s" => view.conversionTime7s,
            "conversionTime15s" => view.conversionTime15s,
            "penaltyKickTime" => view.penaltyKickTime,
            "useConversionTimer" => view.useConversionTimer,
            "usePenaltyTimer" => view.usePenaltyTimer,
            "conversionTeam" => view.conversionTeam,
            "yellowHomeTimes" => view.yellowHomeTimes,
            "yellowAwayTimes" => view.yellowAwayTimes,
            "yellowHomeLabelCounter" => view.yellowHomeLabelCounter,
            "yellowAwayLabelCounter" => view.yellowAwayLabelCounter,
            "yellowHomeTotal" => view.yellowHomeTotal,
            "yellowAwayTotal" => view.yellowAwayTotal,
            "redHome" => view.redHome,
            "redAway" => view.redAway,
            "redHomePermanent" => view.redHomePermanent,
            "redAwayPermanent" => view.redAwayPermanent
        };
        Storage.setValue("gameStateData", snapshot);
    }

    static function finalizeGameData(view) {
        var summary = {
            "homeScore" => view.homeScore,
            "awayScore" => view.awayScore,
            "homeTries" => view.homeTries,
            "awayTries" => view.awayTries,
            "halfNumber" => view.halfNumber,
            "elapsedTime" => view.elapsedTime,
            "countdownRemaining" => view.countdownRemaining,
            "yellowHomeTimes" => view.yellowHomeTimes,
            "yellowAwayTimes" => view.yellowAwayTimes,
            "redHome" => view.redHome,
            "redAway" => view.redAway,
            "redHomePermanent" => view.redHomePermanent,
            "redAwayPermanent" => view.redAwayPermanent
        };
        summary["yellowHomeTotal"] = view.yellowHomeTotal;
        summary["yellowAwayTotal"] = view.yellowAwayTotal;
        summary["redHomeTotal"] = view.redHomeTotal;
        summary["redAwayTotal"] = view.redAwayTotal;
        var eventLogText = RugbyTimerEventLog.buildEventLogText(view);
        if (eventLogText.length() > 0) {
            summary["eventLog"] = eventLogText;
        }
        Storage.setValue("lastGameSummary", summary);
    }

    static function loadSavedState(view) {
        var data = Storage.getValue("gameStateData") as Lang.Dictionary;
        if (data != null) {
            try {
                view.homeScore = data["homeScore"];
                view.awayScore = data["awayScore"];
                view.homeTries = data["homeTries"];
                view.awayTries = data["awayTries"];
                view.halfNumber = data["halfNumber"];
                view.gameTime = data["gameTime"];
                view.elapsedTime = data["elapsedTime"];
                view.countdownRemaining = data["countdownRemaining"];
                view.countdownSeconds = data["countdownSeconds"];
                view.gameState = data["gameState"];
                view.is7s = data["is7s"];
                view.countdownTimer = data["countdownTimer"];
                view.conversionTime7s = data["conversionTime7s"];
                view.conversionTime15s = data["conversionTime15s"];
                view.penaltyKickTime = data["penaltyKickTime"];
                view.useConversionTimer = data["useConversionTimer"];
                view.usePenaltyTimer = data["usePenaltyTimer"];
                view.conversionTeam = data["conversionTeam"];
                var yHomeArr = data["yellowHomeTimes"];
                if (yHomeArr != null) {
                    view.yellowHomeTimes = RugbyTimerCards.normalizeYellowTimers(view, yHomeArr, true);
                } else {
                    view.yellowHomeTimes = [];
                }
                view.yellowHomeLabelCounter = RugbyTimerCards.computeYellowLabelCounter(view.yellowHomeTimes);
                var savedHomeLabelCounter = data["yellowHomeLabelCounter"];
                if (savedHomeLabelCounter != null && savedHomeLabelCounter > view.yellowHomeLabelCounter) {
                    view.yellowHomeLabelCounter = savedHomeLabelCounter;
                }
                var yAwayArr = data["yellowAwayTimes"];
                if (yAwayArr != null) {
                    view.yellowAwayTimes = RugbyTimerCards.normalizeYellowTimers(view, yAwayArr, false);
                } else {
                    view.yellowAwayTimes = [];
                }
                view.yellowAwayLabelCounter = RugbyTimerCards.computeYellowLabelCounter(view.yellowAwayTimes);
                var savedAwayLabelCounter = data["yellowAwayLabelCounter"];
                if (savedAwayLabelCounter != null && savedAwayLabelCounter > view.yellowAwayLabelCounter) {
                    view.yellowAwayLabelCounter = savedAwayLabelCounter;
                }
                view.redHome = data["redHome"];
                if (view.redHome == null) { view.redHome = 0; }
                view.redAway = data["redAway"];
                if (view.redAway == null) { view.redAway = 0; }
                view.redHomePermanent = data["redHomePermanent"];
                if (view.redHomePermanent == null) { view.redHomePermanent = false; }
                view.redAwayPermanent = data["redAwayPermanent"];
                if (view.redAwayPermanent == null) { view.redAwayPermanent = false; }
                view.yellowHomeTotal = data["yellowHomeTotal"];
                if (view.yellowHomeTotal == null) { view.yellowHomeTotal = 0; }
                view.yellowAwayTotal = data["yellowAwayTotal"];
                if (view.yellowAwayTotal == null) { view.yellowAwayTotal = 0; }
                view.redHomeTotal = data["redHomeTotal"];
                if (view.redHomeTotal == null) { view.redHomeTotal = 0; }
                view.redAwayTotal = data["redAwayTotal"];
                if (view.redAwayTotal == null) { view.redAwayTotal = 0; }
            } catch (ex) {
                // ignore malformed state
            }
        }
        if (view.yellowHomeTimes == null) {
            view.yellowHomeTimes = [];
        }
        if (view.yellowAwayTimes == null) {
            view.yellowAwayTimes = [];
        }
    }
}
