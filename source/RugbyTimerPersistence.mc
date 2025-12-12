using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.System;

/**
 * A helper class for saving and loading the game state.
 */
class RugbyTimerPersistence {
    /**
     * Saves the current game state to storage.
     * @param model The game model
     */
    static function saveState(model as RugbyGameModel) as Void {
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
            "redAwayPermanent" => model.redAwayPermanent,
            "countdownStartedAt" => model.countdownStartedAt,
            "countdownInitialValue" => model.countdownInitialValue
        } as Lang.Dictionary;
        Storage.setValue("gameStateData", snapshot);
    }

    /**
     * Finalizes the game data and saves a summary to storage.
     * @param model The game model
     */
    static function finalizeGameData(model as RugbyGameModel) as Void {
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
        } as Lang.Dictionary;
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

    /**
     * Loads the saved game state from storage.
     * @param model The game model
     */
    static function loadSavedState(model as RugbyGameModel) as Void {
        var data = Storage.getValue("gameStateData") as Lang.Dictionary or Null;
        if (data != null) {
            try {
                model.homeScore = data["homeScore"] as Lang.Number;
                model.awayScore = data["awayScore"] as Lang.Number;
                model.homeTries = data["homeTries"] as Lang.Number;
                model.awayTries = data["awayTries"] as Lang.Number;
                model.halfNumber = data["halfNumber"] as Lang.Number;
                model.gameTime = data["gameTime"] as Lang.Float;
                model.elapsedTime = data["elapsedTime"] as Lang.Number;
                model.countdownRemaining = data["countdownRemaining"] as Lang.Float;
                model.countdownSeconds = data["countdownSeconds"] as Lang.Float;
                model.gameState = data["gameState"] as Lang.Number;
                model.is7s = data["is7s"] as Lang.Boolean;
                model.countdownTimer = data["countdownTimer"] as Lang.Number;
                model.conversionTime7s = data["conversionTime7s"] as Lang.Number;
                model.conversionTime15s = data["conversionTime15s"] as Lang.Number;
                model.penaltyKickTime = data["penaltyKickTime"] as Lang.Number;
                model.useConversionTimer = data["useConversionTimer"] as Lang.Boolean;
                model.usePenaltyTimer = data["usePenaltyTimer"] as Lang.Boolean;
                model.conversionTeam = data["conversionTeam"] as Lang.Boolean or Null;
                var yHomeArr = data["yellowHomeTimes"] as Lang.Array or Null;
                if (yHomeArr != null) {
                    model.yellowHomeTimes = RugbyTimerCards.normalizeYellowTimers(model, yHomeArr, true) as Lang.Array;
                } else {
                    model.yellowHomeTimes = [] as Lang.Array;
                }
                model.yellowHomeLabelCounter = RugbyTimerCards.computeYellowLabelCounter(model.yellowHomeTimes) as Lang.Number;
                var savedHomeLabelCounter = data["yellowHomeLabelCounter"] as Lang.Number or Null;
                if (savedHomeLabelCounter != null && savedHomeLabelCounter > model.yellowHomeLabelCounter) {
                    model.yellowHomeLabelCounter = savedHomeLabelCounter;
                }
                var yAwayArr = data["yellowAwayTimes"] as Lang.Array or Null;
                if (yAwayArr != null) {
                    model.yellowAwayTimes = RugbyTimerCards.normalizeYellowTimers(model, yAwayArr, false) as Lang.Array;
                } else {
                    model.yellowAwayTimes = [] as Lang.Array;
                }
                model.yellowAwayLabelCounter = RugbyTimerCards.computeYellowLabelCounter(model.yellowAwayTimes) as Lang.Number;
                var savedAwayLabelCounter = data["yellowAwayLabelCounter"] as Lang.Number or Null;
                if (savedAwayLabelCounter != null && savedAwayLabelCounter > model.yellowAwayLabelCounter) {
                    model.yellowAwayLabelCounter = savedAwayLabelCounter;
                }
                model.redHome = (data["redHome"] as Lang.Float or Null);
                if (model.redHome == null) { model.redHome = 0.0f; }
                model.redAway = (data["redAway"] as Lang.Float or Null);
                if (model.redAway == null) { model.redAway = 0.0f; }
                model.redHomePermanent = (data["redHomePermanent"] as Lang.Boolean or Null);
                if (model.redHomePermanent == null) { model.redHomePermanent = false; }
                model.redAwayPermanent = (data["redAwayPermanent"] as Lang.Boolean or Null);
                if (model.redAwayPermanent == null) { model.redAwayPermanent = false; }
                model.yellowHomeTotal = (data["yellowHomeTotal"] as Lang.Number or Null);
                if (model.yellowHomeTotal == null) { model.yellowHomeTotal = 0; }
                model.yellowAwayTotal = (data["yellowAwayTotal"] as Lang.Number or Null);
                if (model.yellowAwayTotal == null) { model.yellowAwayTotal = 0; }
                model.redHomeTotal = (data["redHomeTotal"] as Lang.Number or Null);
                if (model.redHomeTotal == null) { model.redHomeTotal = 0; }
                model.redAwayTotal = (data["redAwayTotal"] as Lang.Number or Null);
                if (model.redAwayTotal == null) { model.redAwayTotal = 0; }

                // Load new fields
                model.countdownStartedAt = (data["countdownStartedAt"] as Lang.Number or Null);
                if (model.countdownStartedAt == null) { model.countdownStartedAt = 0; }
                model.countdownInitialValue = (data["countdownInitialValue"] as Lang.Float or Null);
                if (model.countdownInitialValue == null) { model.countdownInitialValue = 0.0f; }


            } catch (ex) {
                System.println("Error loading saved state: " + ex.getErrorMessage());
            }
        }
        if (model.yellowHomeTimes == null) {
            model.yellowHomeTimes = [] as Lang.Array;
        }
        if (model.yellowAwayTimes == null) {
            model.yellowAwayTimes = [] as Lang.Array;
        }
    }
}
