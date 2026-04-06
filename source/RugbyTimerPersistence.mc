using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.System;

/**
 * Storage adapter for live match snapshots and final summaries.
 *
 * Purpose: isolate Storage key reads/writes, compatibility defaults, and
 * snapshot shaping from the game model and UI code.
 */
class RugbyTimerPersistence {
    static function isSnapshotUsable(snapshot) {
        if (snapshot == null) {
            return false;
        }
        if (!RugbyTimeMath.isNumeric(snapshot.homeScore)) { return false; }
        if (!RugbyTimeMath.isNumeric(snapshot.awayScore)) { return false; }
        if (!RugbyTimeMath.isNumeric(snapshot.homeTries)) { return false; }
        if (!RugbyTimeMath.isNumeric(snapshot.awayTries)) { return false; }
        if (!RugbyTimeMath.isNumeric(snapshot.halfNumber)) { return false; }
        if (!RugbyTimeMath.isNumeric(snapshot.gameTime)) { return false; }
        if (!RugbyTimeMath.isNumeric(snapshot.elapsedTime)) { return false; }
        if (!RugbyTimeMath.isNumeric(snapshot.countdownTimer)) { return false; }
        return snapshot.gameState instanceof Lang.Number;
    }

    static function clearInvalidSavedState(model, reason) {
        System.println("Clearing invalid saved state: " + reason);
        Storage.setValue(STORAGE_KEY_GAME_STATE_DATA, null);
        model.resetMatchRuntimeState();
        model.setStatusMessage("Saved match reset");
    }

    /**
     * Saves the current game state to storage.
     * @param model The game model
     */
    static function saveState(model) {
        var snapshot = RugbyTimerPersistence.buildSnapshot(model);
        Storage.setValue(STORAGE_KEY_GAME_STATE_DATA, snapshot.toDict());
    }

    static function buildSnapshot(model) {
        var persistedStates = RugbyTimerPersistence.getPersistedStates(model);
        var snapshotElapsedTime = RugbyTimerPersistence.getSnapshotElapsedTime(model);
        var snapshotGameTime = RugbyTimerPersistence.getSnapshotGameTime(model);
        var snapshotSuspensionTime = RugbyTimerPersistence.getSnapshotSuspensionTime(model);
        var snapshotCountdownRemaining = RugbyTimeMath.getCountdownRemaining(model.countdownTimer, snapshotGameTime);
        var snapshotCountdownSeconds = RugbyTimerPersistence.getSnapshotCountdownSeconds(model);
        var snapshot = new PersistedGameSnapshot();
        snapshot.homeScore = model.homeScore;
        snapshot.awayScore = model.awayScore;
        snapshot.homeTries = model.homeTries;
        snapshot.awayTries = model.awayTries;
        snapshot.halfNumber = model.halfNumber;
        snapshot.gameTime = snapshotGameTime;
        snapshot.suspensionTime = snapshotSuspensionTime;
        snapshot.elapsedTime = snapshotElapsedTime;
        snapshot.countdownRemaining = snapshotCountdownRemaining;
        snapshot.countdownSeconds = snapshotCountdownSeconds;
        snapshot.gameState = persistedStates.gameState;
        snapshot.pausedState = persistedStates.pausedState;
        snapshot.matchProfileId = model.matchProfileId;
        snapshot.is7s = model.is7s;
        snapshot.countdownTimer = model.countdownTimer;
        snapshot.conversionTime = model.conversionTime;
        snapshot.kickoffTime = model.kickoffTime;
        snapshot.penaltyKickTime = model.penaltyKickTime;
        snapshot.useConversionTimer = model.useConversionTimer;
        snapshot.usePenaltyTimer = model.usePenaltyTimer;
        snapshot.conversionTeam = model.conversionTeam;
        snapshot.yellowHomeTimes = RugbyTimerPersistence.serializeYellowTimers(model.yellowHomeTimes, snapshotSuspensionTime);
        snapshot.yellowAwayTimes = RugbyTimerPersistence.serializeYellowTimers(model.yellowAwayTimes, snapshotSuspensionTime);
        snapshot.yellowHomeLabelCounter = model.yellowHomeLabelCounter;
        snapshot.yellowAwayLabelCounter = model.yellowAwayLabelCounter;
        snapshot.redHomeLabelCounter = model.redHomeLabelCounter;
        snapshot.redAwayLabelCounter = model.redAwayLabelCounter;
        snapshot.yellowHomeTotal = model.yellowHomeTotal;
        snapshot.yellowAwayTotal = model.yellowAwayTotal;
        snapshot.redHomeTimes = RugbyTimerPersistence.serializeYellowTimers(model.redHomeTimes, snapshotSuspensionTime);
        snapshot.redAwayTimes = RugbyTimerPersistence.serializeYellowTimers(model.redAwayTimes, snapshotSuspensionTime);
        snapshot.redHomePermanent = model.redHomePermanent;
        snapshot.redAwayPermanent = model.redAwayPermanent;
        snapshot.redHomeTotal = model.redHomeTotal;
        snapshot.redAwayTotal = model.redAwayTotal;
        snapshot.homePenalties = model.homePenalties;
        snapshot.awayPenalties = model.awayPenalties;
        snapshot.lastEvents = model.lastEvents;
        snapshot.eventLogEntries = model.eventLogEntries;
        return snapshot;
    }

    /**
     * Finalizes the game data and saves a summary to storage.
     * @param model The game model
     */
    static function finalizeGameData(model) {
        var summary = new MatchSummaryEntry();
        summary.homeScore = model.homeScore;
        summary.awayScore = model.awayScore;
        summary.homeTries = model.homeTries;
        summary.awayTries = model.awayTries;
        summary.halfNumber = model.halfNumber;
        summary.elapsedTime = model.elapsedTime;
        summary.countdownRemaining = model.countdownRemaining;
        summary.yellowHomeTimes = model.yellowHomeTimes;
        summary.yellowAwayTimes = model.yellowAwayTimes;
        summary.redHomeActive = (model.redHomePermanent || model.redHomeTimes.size() > 0);
        summary.redAwayActive = (model.redAwayPermanent || model.redAwayTimes.size() > 0);
        summary.redHomePermanent = model.redHomePermanent;
        summary.redAwayPermanent = model.redAwayPermanent;
        summary.yellowHomeTotal = model.yellowHomeTotal;
        summary.yellowAwayTotal = model.yellowAwayTotal;
        summary.redHomeTotal = model.redHomeTotal;
        summary.redAwayTotal = model.redAwayTotal;
        summary.homeTeamLabel = RugbyTeamIdentitySupport.getTeamLabel(model, true);
        summary.awayTeamLabel = RugbyTeamIdentitySupport.getTeamLabel(model, false);
        var eventLogText = RugbyTimerEventLog.buildEventLogText(model);
        if (eventLogText.length() > 0) {
            summary.eventLog = eventLogText;
        }
        Storage.setValue(STORAGE_KEY_LAST_GAME_SUMMARY, summary.toDict());
    }

    /**
     * Loads the saved game state from storage.
     * @param model The game model
     */
    static function loadSavedState(model) {
        var snapshot = PersistedGameSnapshot.fromDict(Storage.getValue(STORAGE_KEY_GAME_STATE_DATA));
        if (snapshot != null) {
            if (!RugbyTimerPersistence.isSnapshotUsable(snapshot)) {
                RugbyTimerPersistence.clearInvalidSavedState(model, "missing required fields");
                return;
            }
            try {
                RugbyTimerPersistence.applySnapshot(model, snapshot, System.getTimer());
            } catch (ex) {
                Toybox.System.println("Error loading saved state: " + ex.getErrorMessage());
                RugbyTimerPersistence.clearInvalidSavedState(model, ex.getErrorMessage());
                return;
            }
        }
        if (model.yellowHomeTimes == null) {
            model.yellowHomeTimes = [];
        }
        if (model.yellowAwayTimes == null) {
            model.yellowAwayTimes = [];
        }
        if (model.redHomeTimes == null) {
            model.redHomeTimes = [];
        }
        if (model.redAwayTimes == null) {
            model.redAwayTimes = [];
        }
    }

    static function applySnapshot(model, snapshot, now) {
        RugbyTimerPersistence.applyCoreSnapshotFields(model, snapshot);
        RugbyTimerPersistence.applyProfileSnapshotFields(model, snapshot);
        RugbyTimerPersistence.applyHistorySnapshotFields(model, snapshot);
        RugbyTimerPersistence.applyCardSnapshotFields(model, snapshot, now);
        RugbyTimerPersistence.applyCounterSnapshotFields(model, snapshot);
        RugbyTimerPersistence.applyRestoredClockAnchors(model, now);
    }

    static function applyCoreSnapshotFields(model, snapshot) {
        model.homeScore = snapshot.homeScore;
        model.awayScore = snapshot.awayScore;
        model.homeTries = snapshot.homeTries;
        model.awayTries = snapshot.awayTries;
        model.halfNumber = snapshot.halfNumber;
        model.gameTime = snapshot.gameTime;
        model.elapsedTime = snapshot.elapsedTime;
        model.suspensionTime = snapshot.suspensionTime;
        if (!RugbyTimeMath.isNumeric(model.suspensionTime)) {
            model.suspensionTime = model.gameTime;
        }
        model.countdownRemaining = snapshot.countdownRemaining;
        model.countdownSeconds = snapshot.countdownSeconds;
        model.gameState = RugbyTimerPersistence.restoreGameState(snapshot.gameState);
        model.pausedState = RugbyTimerPersistence.restorePausedState(model.gameState, snapshot.gameState, snapshot.pausedState);
        model.conversionTeam = snapshot.conversionTeam;
    }

    static function applyProfileSnapshotFields(model, snapshot) {
        model.matchProfileId = snapshot.matchProfileId;
        model.is7s = snapshot.is7s;
        model.countdownTimer = snapshot.countdownTimer;
        model.conversionTime = RugbyTimerPersistence.restoreConversionTime(snapshot);
        model.kickoffTime = RugbyTimerPersistence.restoreKickoffTime(snapshot.kickoffTime, model.is7s);
        model.penaltyKickTime = snapshot.penaltyKickTime;
        model.useConversionTimer = snapshot.useConversionTimer;
        model.usePenaltyTimer = snapshot.usePenaltyTimer;
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
    }

    static function applyHistorySnapshotFields(model, snapshot) {
        model.lastEvents = snapshot.lastEvents;
        if (model.lastEvents == null) { model.lastEvents = []; }
        model.eventLogEntries = snapshot.eventLogEntries;
        if (model.eventLogEntries == null) { model.eventLogEntries = []; }
    }

    static function applyCardSnapshotFields(model, snapshot, now) {
        model.yellowHomeTimes = RugbyTimerPersistence.restoreYellowTimers(snapshot.yellowHomeTimes, model.suspensionTime, now);
        model.yellowAwayTimes = RugbyTimerPersistence.restoreYellowTimers(snapshot.yellowAwayTimes, model.suspensionTime, now);
        model.redHomeTimes = RugbyTimerPersistence.restoreYellowTimers(snapshot.redHomeTimes, model.suspensionTime, now);
        model.redAwayTimes = RugbyTimerPersistence.restoreYellowTimers(snapshot.redAwayTimes, model.suspensionTime, now);
        model.redHomePermanent = snapshot.redHomePermanent;
        if (model.redHomePermanent == null) { model.redHomePermanent = false; }
        model.redAwayPermanent = snapshot.redAwayPermanent;
        if (model.redAwayPermanent == null) { model.redAwayPermanent = false; }
    }

    static function applyCounterSnapshotFields(model, snapshot) {
        model.yellowHomeLabelCounter = RugbyTimerPersistence.orZero(snapshot.yellowHomeLabelCounter);
        model.yellowAwayLabelCounter = RugbyTimerPersistence.orZero(snapshot.yellowAwayLabelCounter);
        model.redHomeLabelCounter = RugbyTimerPersistence.orZero(snapshot.redHomeLabelCounter);
        model.redAwayLabelCounter = RugbyTimerPersistence.orZero(snapshot.redAwayLabelCounter);
        model.yellowHomeTotal = RugbyTimerPersistence.orZero(snapshot.yellowHomeTotal);
        model.yellowAwayTotal = RugbyTimerPersistence.orZero(snapshot.yellowAwayTotal);
        model.redHomeTotal = RugbyTimerPersistence.orZero(snapshot.redHomeTotal);
        model.redAwayTotal = RugbyTimerPersistence.orZero(snapshot.redAwayTotal);
        model.homePenalties = RugbyTimerPersistence.orZero(snapshot.homePenalties);
        model.awayPenalties = RugbyTimerPersistence.orZero(snapshot.awayPenalties);
    }

    static function applyRestoredClockAnchors(model, now) {
        if (model.gameState == STATE_IDLE || model.gameState == STATE_ENDED) {
            return;
        }
        if (!RugbyTimeMath.isNumeric(model.gameTime)) { model.gameTime = 0; }
        if (model.gameState == STATE_PAUSED || model.gameState == STATE_HALFTIME) {
            model.gameStartTime = null;
            model.lastUpdate = null;
            return;
        }
        model.gameStartTime = now - (model.gameTime * 1000.0f);
        model.lastUpdate = now;
    }

    static function orZero(value) {
        if (value == null) {
            return 0;
        }
        return value;
    }

    static function getPersistedStates(model) {
        if (RugbyMatchStateSupport.shouldRestoreAsPaused(model.gameState)) {
            return PersistedStatePair.create(STATE_PAUSED, model.gameState);
        }
        return PersistedStatePair.create(model.gameState, model.pausedState);
    }

    static function getSnapshotGameTime(model) {
        return RugbyTimeMath.snapshotForwardClock(model.gameTime, model.lastUpdate, System.getTimer(), RugbyTimerTiming.isClockRunning(model.gameState));
    }

    static function getSnapshotElapsedTime(model) {
        return RugbyTimeMath.snapshotForwardClock(model.elapsedTime, model.lastUpdate, System.getTimer(), model.gameState != STATE_IDLE && model.gameState != STATE_ENDED);
    }

    static function getSnapshotSuspensionTime(model) {
        return RugbyTimeMath.snapshotForwardClock(model.suspensionTime, model.lastUpdate, System.getTimer(), RugbyTimerTiming.isSuspensionClockRunning(model.gameState));
    }

    static function getSnapshotCountdownSeconds(model) {
        return RugbyTimeMath.snapshotReverseClock(model.countdownSeconds, model.lastUpdate, System.getTimer(), model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY);
    }

    static function serializeYellowTimers(list, clockValue) {
        var serialized = [];
        if (!(list instanceof Lang.Array)) {
            return serialized;
        }
        var entries = list as Lang.Array;
        for (var i = 0; i < entries.size(); i = i + 1) {
            var entry = CardEntry.fromDict(entries[i]);
            if (entry == null) {
                continue;
            }
            var duration = entry.duration;
            var remaining = entry.remaining;
            var clockStart = entry.startTime;
            if (RugbyTimeMath.isNumeric(duration) && RugbyTimeMath.isNumeric(clockStart) && RugbyTimeMath.isNumeric(clockValue)) {
                remaining = duration - (clockValue - clockStart);
            }
            if (!RugbyTimeMath.isNumeric(duration) && RugbyTimeMath.isNumeric(remaining)) {
                duration = remaining;
            }
            if (!RugbyTimeMath.isNumeric(remaining) || !RugbyTimeMath.isNumeric(duration)) {
                continue;
            }
            if (remaining <= 0) {
                continue;
            }
            if (remaining > duration) { remaining = duration; }
            serialized.add(PersistedCardTimerEntry.create(duration, clockStart, remaining, entry.label, entry.cardId, entry.vibeTriggered).toDict());
        }
        return serialized;
    }

    static function restoreYellowTimers(list, clockValue, now) {
        var restored = [];
        if (!(list instanceof Lang.Array)) {
            return restored;
        }
        var entries = list as Lang.Array;
        for (var i = 0; i < entries.size(); i = i + 1) {
            var entry = PersistedCardTimerEntry.fromDict(entries[i]);
            if (entry == null) {
                continue;
            }
            var duration = entry.duration;
            var remaining = entry.remaining;
            var clockStart = entry.clockStart;
            if (!RugbyTimeMath.isNumeric(clockStart)) {
                var activeEntry = CardEntry.fromDict(entries[i]);
                if (activeEntry != null) {
                    clockStart = activeEntry.startTime;
                }
            }
            if (!RugbyTimeMath.isNumeric(remaining) && RugbyTimeMath.isNumeric(duration) && RugbyTimeMath.isNumeric(clockStart) && RugbyTimeMath.isNumeric(clockValue)) {
                if (entry.clockStart instanceof Lang.Number || entry.clockStart instanceof Lang.Float) {
                    remaining = duration - (clockValue - clockStart);
                } else {
                    remaining = duration - ((now - clockStart) / 1000.0f);
                }
            }
            if (!RugbyTimeMath.isNumeric(duration) && RugbyTimeMath.isNumeric(remaining)) {
                duration = remaining;
            }
            if (!RugbyTimeMath.isNumeric(remaining) || !RugbyTimeMath.isNumeric(duration)) {
                continue;
            }
            if (remaining <= 0) {
                continue;
            }
            if (remaining > duration) { remaining = duration; }
            if (!RugbyTimeMath.isNumeric(clockStart) && RugbyTimeMath.isNumeric(clockValue)) {
                clockStart = clockValue - (duration - remaining);
            }
            var active = CardEntry.createFromStartTime(clockStart, duration, entry.label, entry.cardId);
            active.vibeTriggered = entry.vibeTriggered == true;
            active.remaining = remaining;
            restored.add(active.toDict());
        }
        return restored;
    }

    static function restoreConversionTime(snapshot) {
        var conversionTime = snapshot.conversionTime;
        if (conversionTime instanceof Lang.Number) {
            return conversionTime;
        }
        var is7s = snapshot.is7s == true;
        conversionTime = is7s ? snapshot.conversionTime7s : snapshot.conversionTime15s;
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
        if (RugbyMatchStateSupport.shouldRestoreAsPaused(savedGameState)) {
            return STATE_PAUSED;
        }
        return savedGameState;
    }

    static function restorePausedState(restoredGameState, savedGameState, savedPausedState) {
        if (restoredGameState == STATE_PAUSED) {
            return RugbyMatchStateSupport.getRestoredPausedState(savedGameState, savedPausedState);
        }
        return savedPausedState;
    }
}
