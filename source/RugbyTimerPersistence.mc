using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.System;

/**
 * A helper class for saving and loading the game state.
 */
class RugbyTimerPersistence {
    static function isNumeric(value) {
        return value instanceof Lang.Number || value instanceof Lang.Float;
    }

    /**
     * Saves the current game state to storage.
     * @param model The game model
     */
    static function saveState(model) {
        var persistedStates = RugbyTimerPersistence.getPersistedStates(model);
        var snapshot = {
            "homeScore" => model.homeScore,
            "awayScore" => model.awayScore,
            "homeTries" => model.homeTries,
            "awayTries" => model.awayTries,
            "halfNumber" => model.halfNumber,
            "gameTime" => RugbyTimerPersistence.getSnapshotGameTime(model),
            "elapsedTime" => model.elapsedTime,
            "countdownRemaining" => model.countdownRemaining,
            "countdownSeconds" => model.countdownSeconds,
            "gameState" => persistedStates[:gameState],
            "pausedState" => persistedStates[:pausedState],
            "matchProfileId" => model.matchProfileId,
            "is7s" => model.is7s,
            "countdownTimer" => model.countdownTimer,
            "conversionTime" => model.conversionTime,
            "kickoffTime" => model.kickoffTime,
            "penaltyKickTime" => model.penaltyKickTime,
            "useConversionTimer" => model.useConversionTimer,
            "usePenaltyTimer" => model.usePenaltyTimer,
            "conversionTeam" => model.conversionTeam,
            "yellowHomeTimes" => RugbyTimerPersistence.serializeYellowTimers(model.yellowHomeTimes),
            "yellowAwayTimes" => RugbyTimerPersistence.serializeYellowTimers(model.yellowAwayTimes),
            "yellowHomeLabelCounter" => model.yellowHomeLabelCounter,
            "yellowAwayLabelCounter" => model.yellowAwayLabelCounter,
            "yellowHomeTotal" => model.yellowHomeTotal,
            "yellowAwayTotal" => model.yellowAwayTotal,
            "redHomeRemaining" => RugbyTimerPersistence.serializeRedRemaining(model.redHome, model.redHomePausedRemaining, model.redHomePermanent),
            "redAwayRemaining" => RugbyTimerPersistence.serializeRedRemaining(model.redAway, model.redAwayPausedRemaining, model.redAwayPermanent),
            "redHomePausedRemaining" => model.redHomePausedRemaining,
            "redAwayPausedRemaining" => model.redAwayPausedRemaining,
            "redHomePermanent" => model.redHomePermanent,
            "redAwayPermanent" => model.redAwayPermanent,
            "redHomeTotal" => model.redHomeTotal,
            "redAwayTotal" => model.redAwayTotal,
            "homePenalties" => model.homePenalties,
            "awayPenalties" => model.awayPenalties,
            "lastEvents" => model.lastEvents,
            "eventLogEntries" => model.eventLogEntries
        };
        Storage.setValue("gameStateData", snapshot);
    }

    /**
     * Finalizes the game data and saves a summary to storage.
     * @param model The game model
     */
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

    /**
     * Loads the saved game state from storage.
     * @param model The game model
     */
    static function loadSavedState(model) {
        var data = Storage.getValue("gameStateData") as Lang.Dictionary;
        if (data != null) {
            try {
                var now = System.getTimer();
                model.homeScore = data["homeScore"];
                model.awayScore = data["awayScore"];
                model.homeTries = data["homeTries"];
                model.awayTries = data["awayTries"];
                model.halfNumber = data["halfNumber"];
                model.gameTime = data["gameTime"];
                model.elapsedTime = data["elapsedTime"];
                model.countdownRemaining = data["countdownRemaining"];
                model.countdownSeconds = data["countdownSeconds"];
                model.gameState = RugbyTimerPersistence.restoreGameState(data["gameState"]);
                model.pausedState = RugbyTimerPersistence.restorePausedState(model.gameState, data["gameState"], data["pausedState"]);
                model.matchProfileId = data["matchProfileId"];
                model.is7s = data["is7s"];
                model.countdownTimer = data["countdownTimer"];
                model.conversionTime = RugbyTimerPersistence.restoreConversionTime(data);
                model.kickoffTime = RugbyTimerPersistence.restoreKickoffTime(data["kickoffTime"], model.is7s);
                model.penaltyKickTime = data["penaltyKickTime"];
                model.useConversionTimer = data["useConversionTimer"];
                model.usePenaltyTimer = data["usePenaltyTimer"];
                if (model.matchProfileId == null) {
                    model.matchProfileId = RugbyMatchProfiles.inferProfileIdFromSettings(
                        model.is7s,
                        model.countdownTimer,
                        model.conversionTime,
                        model.kickoffTime,
                        model.penaltyKickTime,
                        model.useConversionTimer,
                        model.usePenaltyTimer
                    );
                }
                model.conversionTeam = data["conversionTeam"];
                model.lastEvents = data["lastEvents"];
                if (model.lastEvents == null) { model.lastEvents = []; }
                model.eventLogEntries = data["eventLogEntries"];
                if (model.eventLogEntries == null) { model.eventLogEntries = []; }
                
                model.yellowHomeTimes = RugbyTimerPersistence.restoreYellowTimers(data["yellowHomeTimes"], now);
                model.yellowAwayTimes = RugbyTimerPersistence.restoreYellowTimers(data["yellowAwayTimes"], now);
                
                model.yellowHomeLabelCounter = data["yellowHomeLabelCounter"];
                if (model.yellowHomeLabelCounter == null) { model.yellowHomeLabelCounter = 0; }
                model.yellowAwayLabelCounter = data["yellowAwayLabelCounter"];
                if (model.yellowAwayLabelCounter == null) { model.yellowAwayLabelCounter = 0; }
                
                model.redHomePermanent = data["redHomePermanent"];
                if (model.redHomePermanent == null) { model.redHomePermanent = false; }
                model.redAwayPermanent = data["redAwayPermanent"];
                if (model.redAwayPermanent == null) { model.redAwayPermanent = false; }
                model.redHome = RugbyTimerPersistence.restoreRedStartTime(data["redHomeRemaining"], data["redHome"], model.redHomePermanent, now);
                model.redAway = RugbyTimerPersistence.restoreRedStartTime(data["redAwayRemaining"], data["redAway"], model.redAwayPermanent, now);
                model.redHomePausedRemaining = data["redHomePausedRemaining"];
                model.redAwayPausedRemaining = data["redAwayPausedRemaining"];
                if (model.gameState == STATE_PAUSED) {
                    if (!(model.redHomePausedRemaining instanceof Lang.Number) && data["redHomeRemaining"] instanceof Lang.Number) {
                        model.redHomePausedRemaining = data["redHomeRemaining"];
                    }
                    if (!(model.redAwayPausedRemaining instanceof Lang.Number) && data["redAwayRemaining"] instanceof Lang.Number) {
                        model.redAwayPausedRemaining = data["redAwayRemaining"];
                    }
                }

                model.yellowHomeTotal = data["yellowHomeTotal"];
                if (model.yellowHomeTotal == null) { model.yellowHomeTotal = 0; }
                model.yellowAwayTotal = data["yellowAwayTotal"];
                if (model.yellowAwayTotal == null) { model.yellowAwayTotal = 0; }
                model.redHomeTotal = data["redHomeTotal"];
                if (model.redHomeTotal == null) { model.redHomeTotal = 0; }
                model.redAwayTotal = data["redAwayTotal"];
                if (model.redAwayTotal == null) { model.redAwayTotal = 0; }
                
                model.homePenalties = data["homePenalties"];
                if (model.homePenalties == null) { model.homePenalties = 0; }
                model.awayPenalties = data["awayPenalties"];
                if (model.awayPenalties == null) { model.awayPenalties = 0; }

                if (model.gameState != STATE_IDLE && model.gameState != STATE_ENDED) {
                    if (!(model.gameTime instanceof Lang.Number)) { model.gameTime = 0; }
                    if (model.gameState == STATE_PAUSED || model.gameState == STATE_HALFTIME) {
                        model.gameStartTime = null;
                        model.lastUpdate = null;
                    } else {
                        model.gameStartTime = now - (model.gameTime * 1000.0f);
                        model.lastUpdate = now;
                    }
                }
            } catch (ex) {
                Toybox.System.println("Error loading saved state: " + ex.getErrorMessage());
            }
        }
        if (model.yellowHomeTimes == null) {
            model.yellowHomeTimes = [];
        }
        if (model.yellowAwayTimes == null) {
            model.yellowAwayTimes = [];
        }
    }

    static function getPersistedStates(model) {
        if (model.gameState == STATE_PLAYING || model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF) {
            return {
                :gameState => STATE_PAUSED,
                :pausedState => model.gameState
            };
        }
        return {
            :gameState => model.gameState,
            :pausedState => model.pausedState
        };
    }

    static function getSnapshotGameTime(model) {
        return model.gameTime;
    }

    static function serializeYellowTimers(list) {
        var serialized = [];
        if (list == null) {
            return serialized;
        }
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i] as Lang.Dictionary;
            if (entry == null) {
                continue;
            }
            var duration = entry["duration"];
            var remaining = entry["remaining"];
            if (!RugbyTimerPersistence.isNumeric(remaining) && RugbyTimerPersistence.isNumeric(duration) && RugbyTimerPersistence.isNumeric(entry["startTime"])) {
                var now = System.getTimer();
                remaining = duration - ((now - entry["startTime"]) / 1000.0f);
            }
            if (!RugbyTimerPersistence.isNumeric(duration) && RugbyTimerPersistence.isNumeric(remaining)) {
                duration = remaining;
            }
            if (!RugbyTimerPersistence.isNumeric(remaining) || !RugbyTimerPersistence.isNumeric(duration)) {
                continue;
            }
            if (remaining <= 0) {
                continue;
            }
            if (remaining > duration) { remaining = duration; }
            serialized.add({
                "duration" => duration,
                "remaining" => remaining,
                "label" => entry["label"],
                "cardId" => entry["cardId"],
                "vibeTriggered" => entry["vibeTriggered"] == true
            });
        }
        return serialized;
    }

    static function restoreYellowTimers(list, now) {
        var restored = [];
        if (list == null) {
            return restored;
        }
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i] as Lang.Dictionary;
            if (entry == null) {
                continue;
            }
            var duration = entry["duration"];
            var remaining = entry["remaining"];
            if (!RugbyTimerPersistence.isNumeric(remaining) && RugbyTimerPersistence.isNumeric(duration) && RugbyTimerPersistence.isNumeric(entry["startTime"])) {
                remaining = duration - ((now - entry["startTime"]) / 1000.0f);
            }
            if (!RugbyTimerPersistence.isNumeric(duration) && RugbyTimerPersistence.isNumeric(remaining)) {
                duration = remaining;
            }
            if (!RugbyTimerPersistence.isNumeric(remaining) || !RugbyTimerPersistence.isNumeric(duration)) {
                continue;
            }
            if (remaining <= 0) {
                continue;
            }
            if (remaining > duration) { remaining = duration; }
            var elapsed = duration - remaining;
            restored.add({
                "startTime" => now - (elapsed * 1000.0f),
                "duration" => duration,
                "label" => entry["label"],
                "cardId" => entry["cardId"],
                "vibeTriggered" => entry["vibeTriggered"] == true,
                "remaining" => remaining
            });
        }
        return restored;
    }

    static function serializeRedRemaining(startTime, pausedRemaining, isPermanent) {
        if (isPermanent) {
            return 0;
        }
        if (pausedRemaining instanceof Lang.Number) {
            if (pausedRemaining <= 0) {
                return null;
            }
            if (pausedRemaining > 1200) { pausedRemaining = 1200; }
            return pausedRemaining;
        }
        if (!(startTime instanceof Lang.Number)) {
            return null;
        }
        var remaining = 1200 - ((System.getTimer() - startTime) / 1000.0f);
        if (remaining <= 0) {
            return null;
        }
        if (remaining > 1200) { remaining = 1200; }
        return remaining;
    }

    static function restoreRedStartTime(savedRemaining, legacyStartTime, isPermanent, now) {
        if (isPermanent) {
            return 0;
        }
        var remaining = savedRemaining;
        if (!(remaining instanceof Lang.Number) && legacyStartTime instanceof Lang.Number) {
            remaining = 1200 - ((now - legacyStartTime) / 1000.0f);
        }
        if (!(remaining instanceof Lang.Number) || remaining <= 0) {
            return null;
        }
        if (remaining > 1200) { remaining = 1200; }
        return now - ((1200 - remaining) * 1000.0f);
    }

    static function restoreConversionTime(data) {
        var conversionTime = data["conversionTime"];
        if (conversionTime instanceof Lang.Number) {
            return conversionTime;
        }
        var is7s = data["is7s"] == true;
        conversionTime = is7s ? data["conversionTime7s"] : data["conversionTime15s"];
        if (conversionTime instanceof Lang.Number) {
            return conversionTime;
        }
        return is7s ? 30 : 90;
    }

    static function restoreKickoffTime(savedKickoffTime, is7s) {
        if (savedKickoffTime instanceof Lang.Number) {
            return savedKickoffTime;
        }
        return is7s == true ? 30 : 60;
    }

    static function restoreGameState(savedGameState) {
        if (savedGameState == STATE_KICKOFF) {
            return STATE_PAUSED;
        }
        if (savedGameState == STATE_PLAYING || savedGameState == STATE_CONVERSION || savedGameState == STATE_PENALTY) {
            return STATE_PAUSED;
        }
        return savedGameState;
    }

    static function restorePausedState(restoredGameState, savedGameState, savedPausedState) {
        if (restoredGameState == STATE_PAUSED) {
            if (savedPausedState == STATE_KICKOFF) {
                savedPausedState = STATE_PLAYING;
            }
            if (savedPausedState != null) {
                return savedPausedState;
            }
            if (savedGameState == STATE_KICKOFF) {
                return STATE_PLAYING;
            }
            if (savedGameState == STATE_PLAYING || savedGameState == STATE_CONVERSION || savedGameState == STATE_PENALTY) {
                return savedGameState;
            }
            return STATE_PLAYING;
        }
        return savedPausedState;
    }
}
