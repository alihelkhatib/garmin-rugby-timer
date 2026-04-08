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
    static function isNumeric(value) {
        return value instanceof Lang.Number || value instanceof Lang.Float;
    }

    static function isSnapshotUsable(snapshot) {
        if (snapshot == null) {
            return false;
        }
        if (!RugbyTimerPersistence.isNumeric(snapshot.homeScore)) { return false; }
        if (!RugbyTimerPersistence.isNumeric(snapshot.awayScore)) { return false; }
        if (!RugbyTimerPersistence.isNumeric(snapshot.homeTries)) { return false; }
        if (!RugbyTimerPersistence.isNumeric(snapshot.awayTries)) { return false; }
        if (!RugbyTimerPersistence.isNumeric(snapshot.halfNumber)) { return false; }
        if (!RugbyTimerPersistence.isNumeric(snapshot.gameTime)) { return false; }
        if (!RugbyTimerPersistence.isNumeric(snapshot.elapsedTime)) { return false; }
        if (!RugbyTimerPersistence.isNumeric(snapshot.countdownTimer)) { return false; }
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
        var persistedGameState = model.gameState;
        var persistedPausedState = model.pausedState;
        if (model.gameState == STATE_PLAYING || model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF) {
            persistedGameState = STATE_PAUSED;
            persistedPausedState = model.gameState;
        }
        var snapshotElapsedTime = RugbyTimerPersistence.getSnapshotElapsedTime(model);
        var snapshotGameTime = RugbyTimerPersistence.getSnapshotGameTime(model);
        var snapshotSuspensionTime = RugbyTimerPersistence.getSnapshotSuspensionTime(model);
        var snapshotCountdownRemaining = model.countdownTimer - snapshotGameTime;
        if (snapshotCountdownRemaining < 0) { snapshotCountdownRemaining = 0; }
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
        snapshot.gameState = persistedGameState;
        snapshot.pausedState = persistedPausedState;
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
        Storage.setValue(STORAGE_KEY_GAME_STATE_DATA, snapshot.toDict());
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
                var now = System.getTimer();
                model.homeScore = snapshot.homeScore;
                model.awayScore = snapshot.awayScore;
                model.homeTries = snapshot.homeTries;
                model.awayTries = snapshot.awayTries;
                model.halfNumber = snapshot.halfNumber;
                model.gameTime = snapshot.gameTime;
                model.elapsedTime = snapshot.elapsedTime;
                model.suspensionTime = snapshot.suspensionTime;
                if (!(model.suspensionTime instanceof Lang.Number) && !(model.suspensionTime instanceof Lang.Float)) {
                    model.suspensionTime = model.gameTime;
                }
                model.countdownRemaining = snapshot.countdownRemaining;
                model.countdownSeconds = snapshot.countdownSeconds;
                model.gameState = RugbyTimerPersistence.restoreGameState(snapshot.gameState);
                model.pausedState = RugbyTimerPersistence.restorePausedState(model.gameState, snapshot.gameState, snapshot.pausedState);
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
                model.conversionTeam = snapshot.conversionTeam;
                model.lastEvents = snapshot.lastEvents;
                if (model.lastEvents == null) { model.lastEvents = []; }
                model.eventLogEntries = snapshot.eventLogEntries;
                if (model.eventLogEntries == null) { model.eventLogEntries = []; }
                
                model.yellowHomeTimes = RugbyTimerPersistence.restoreYellowTimers(snapshot.yellowHomeTimes, model.suspensionTime, now);
                model.yellowAwayTimes = RugbyTimerPersistence.restoreYellowTimers(snapshot.yellowAwayTimes, model.suspensionTime, now);
                
                model.yellowHomeLabelCounter = snapshot.yellowHomeLabelCounter;
                if (model.yellowHomeLabelCounter == null) { model.yellowHomeLabelCounter = 0; }
                model.yellowAwayLabelCounter = snapshot.yellowAwayLabelCounter;
                if (model.yellowAwayLabelCounter == null) { model.yellowAwayLabelCounter = 0; }
                model.redHomeLabelCounter = snapshot.redHomeLabelCounter;
                if (model.redHomeLabelCounter == null) { model.redHomeLabelCounter = 0; }
                model.redAwayLabelCounter = snapshot.redAwayLabelCounter;
                if (model.redAwayLabelCounter == null) { model.redAwayLabelCounter = 0; }
                
                model.redHomePermanent = snapshot.redHomePermanent;
                if (model.redHomePermanent == null) { model.redHomePermanent = false; }
                model.redAwayPermanent = snapshot.redAwayPermanent;
                if (model.redAwayPermanent == null) { model.redAwayPermanent = false; }
                model.redHomeTimes = RugbyTimerPersistence.restoreYellowTimers(snapshot.redHomeTimes, model.suspensionTime, now);
                model.redAwayTimes = RugbyTimerPersistence.restoreYellowTimers(snapshot.redAwayTimes, model.suspensionTime, now);

                model.yellowHomeTotal = snapshot.yellowHomeTotal;
                if (model.yellowHomeTotal == null) { model.yellowHomeTotal = 0; }
                model.yellowAwayTotal = snapshot.yellowAwayTotal;
                if (model.yellowAwayTotal == null) { model.yellowAwayTotal = 0; }
                model.redHomeTotal = snapshot.redHomeTotal;
                if (model.redHomeTotal == null) { model.redHomeTotal = 0; }
                model.redAwayTotal = snapshot.redAwayTotal;
                if (model.redAwayTotal == null) { model.redAwayTotal = 0; }
                
                model.homePenalties = snapshot.homePenalties;
                if (model.homePenalties == null) { model.homePenalties = 0; }
                model.awayPenalties = snapshot.awayPenalties;
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

    static function getSnapshotGameTime(model) {
        var snapshot = model.gameTime;
        if (!RugbyTimerPersistence.isNumeric(snapshot)) {
            snapshot = 0;
        }
        if (RugbyTimerTiming.isClockRunning(model.gameState) && RugbyTimerPersistence.isNumeric(model.lastUpdate)) {
            var delta = (System.getTimer() - model.lastUpdate) / 1000.0f;
            if (delta > 0) {
                snapshot = snapshot + delta;
            }
        }
        return snapshot;
    }

    static function getSnapshotElapsedTime(model) {
        var snapshot = model.elapsedTime;
        if (!RugbyTimerPersistence.isNumeric(snapshot)) {
            snapshot = 0;
        }
        if (model.gameState != STATE_IDLE && model.gameState != STATE_ENDED && RugbyTimerPersistence.isNumeric(model.lastUpdate)) {
            var delta = (System.getTimer() - model.lastUpdate) / 1000.0f;
            if (delta > 0) {
                snapshot = snapshot + delta;
            }
        }
        return snapshot;
    }

    static function getSnapshotSuspensionTime(model) {
        var snapshot = model.suspensionTime;
        if (!RugbyTimerPersistence.isNumeric(snapshot)) {
            snapshot = 0;
        }
        if (RugbyTimerTiming.isSuspensionClockRunning(model.gameState) && RugbyTimerPersistence.isNumeric(model.lastUpdate)) {
            var delta = (System.getTimer() - model.lastUpdate) / 1000.0f;
            if (delta > 0) {
                snapshot = snapshot + delta;
            }
        }
        return snapshot;
    }

    static function getSnapshotCountdownSeconds(model) {
        var snapshot = model.countdownSeconds;
        if (!RugbyTimerPersistence.isNumeric(snapshot)) {
            snapshot = 0;
        }
        if ((model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY) && RugbyTimerPersistence.isNumeric(model.lastUpdate)) {
            var delta = (System.getTimer() - model.lastUpdate) / 1000.0f;
            if (delta > 0) {
                snapshot = snapshot - delta;
                if (snapshot < 0) { snapshot = 0; }
            }
        }
        return snapshot;
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
            if (RugbyTimerPersistence.isNumeric(duration) && RugbyTimerPersistence.isNumeric(clockStart) && RugbyTimerPersistence.isNumeric(clockValue)) {
                remaining = duration - (clockValue - clockStart);
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
            if (!RugbyTimerPersistence.isNumeric(clockStart)) {
                var activeEntry = CardEntry.fromDict(entries[i]);
                if (activeEntry != null) {
                    clockStart = activeEntry.startTime;
                }
            }
            if (!RugbyTimerPersistence.isNumeric(remaining) && RugbyTimerPersistence.isNumeric(duration) && RugbyTimerPersistence.isNumeric(clockStart) && RugbyTimerPersistence.isNumeric(clockValue)) {
                if (entry.clockStart instanceof Lang.Number || entry.clockStart instanceof Lang.Float) {
                    remaining = duration - (clockValue - clockStart);
                } else {
                    remaining = duration - ((now - clockStart) / 1000.0f);
                }
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
            if (!RugbyTimerPersistence.isNumeric(clockStart) && RugbyTimerPersistence.isNumeric(clockValue)) {
                clockStart = clockValue - (duration - remaining);
            }
            var active = CardEntry.createFromStartTime(clockStart, duration, entry.label, entry.cardId);
            active.vibeTriggered = entry.vibeTriggered == true;
            active.remaining = remaining;
            restored.add(active.toDict());
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
