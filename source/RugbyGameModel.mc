using Toybox.Application.Storage;
using Toybox.System;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.Lang;

// Represents the game state
enum {
    STATE_IDLE,
    STATE_PLAYING,
    STATE_PAUSED,
    STATE_CONVERSION,
    STATE_PENALTY,
    STATE_KICKOFF,
    STATE_HALFTIME,
    STATE_ENDED
}

/**
 * Public game-state facade for the rugby timer app.
 *
 * Purpose: hold the canonical match state while delegating most state-changing
 * behavior to focused services such as clock, scoring, discipline, recording,
 * and snapshot helpers.
 */
class RugbyGameModel {
    // The current state of the game, one of the STATE_* enum values
    var gameState;
    // The score of the home team
    var homeScore;
    // The score of the away team
    var awayScore;
    // The number of tries scored by the home team
    var homeTries;
    // The number of tries scored by the away team
    var awayTries;
    // The current half number (1 or 2)
    var halfNumber;
    // The number of seconds for the current countdown (e.g., for conversion, penalty)
    var countdownSeconds;
    // The main game time in seconds (can be paused)
    var gameTime;
    // The sanction clock in seconds for yellow/red timers
    var suspensionTime;
    // The total elapsed time in seconds since the game started (always running)
    var elapsedTime;
    // The timestamp of the last update
    var lastUpdate;
    // The timestamp when the game started
    var gameStartTime;
    
    // The current activity recording session
    var session;
    // One-shot UI/log status text about activity recording support/failure
    var recordingStatusMessage;
    // A boolean indicating if the game is a 7s or 15s match
    var is7s;
    // The selected preset/profile id
    var matchProfileId;
    // The duration of a half in seconds
    var halfDuration;
    // The configured duration for the main countdown timer
    var countdownTimer;
    // The remaining time for the main countdown timer
    var countdownRemaining;
    // An array of GPS track points
    var gpsTrack;
    // An array of the last scoring events for the undo functionality
    var lastEvents;
    // An array of all game events for the event log
    var eventLogEntries;
    // The timestamp of the last time the state was persisted
    var lastPersistTime;
    // The active duration of the conversion timer
    var conversionTime;
    // The team that is currently attempting a conversion (true for home, false for away)
    var conversionTeam;
    // The active duration of the kickoff timer
    var kickoffTime;
    // The duration of the penalty kick timer
    var penaltyKickTime;
    // A boolean indicating if the conversion timer should be used
    var useConversionTimer;
    // A boolean indicating if the penalty timer should be used
    var usePenaltyTimer;
    // A boolean indicating if the screen should be locked on game start
    var lockOnStart;
    // A flag to ensure the low time alert is triggered only once
    var lowAlertTriggered;
    // A flag to ensure the 30-second alert is triggered only once
    var thirtySecondAlerted;
    // Timestamp of the last paused reminder vibration
    var lastPauseReminderTime;
    // The game state before it was paused
    var pausedState;
    // An array of timers for yellow cards for the home team
    var yellowHomeTimes;
    // An array of timers for yellow cards for the away team
    var yellowAwayTimes;
    // A counter for the labels of yellow cards for the home team
    var yellowHomeLabelCounter;
    // A counter for the labels of yellow cards for the away team
    var yellowAwayLabelCounter;
    // A counter for the labels of red cards for the home team
    var redHomeLabelCounter;
    // A counter for the labels of red cards for the away team
    var redAwayLabelCounter;
    // Timed red card entries for the home team (same structure as yellow card entries)
    var redHomeTimes;
    // Timed red card entries for the away team (same structure as yellow card entries)
    var redAwayTimes;
    // A boolean indicating if the red card for the home team is permanent
    var redHomePermanent;
    // A boolean indicating if the red card for the away team is permanent
    var redAwayPermanent;
    // The total number of yellow cards for the home team
    var yellowHomeTotal;
    // The total number of yellow cards for the away team
    var yellowAwayTotal;
    // The total number of red cards for the home team
    var redHomeTotal;
    // The total number of red cards for the away team
    var redAwayTotal;
    // The total number of penalties for the home team
    var homePenalties;
    // The total number of penalties for the away team
    var awayPenalties;
    // The timestamp when the special timer (conversion, penalty) started
    var conversionStartTime;
    // The timestamp when the penalty timer started
    var penaltyStartTime;
    // The timestamp when the kickoff timer started
    var kickoffStartTime;
    // A flag to ensure the special timer alert is triggered only once
    var specialAlertTriggered;
    
    // The current position information from the GPS
    var positionInfo;
    // The total distance covered during the activity
    var distance;
    // The current speed
    var speed;
    
    // Timers
    const PENALTY_KICK_TIME = 60;    // 60 seconds for penalty kicks
    const MAX_TRACK_POINTS = 200;
    const STATE_SAVE_INTERVAL_MS = 5000;
    
    /**
     * Initializes the game model.
     * Loads settings from storage and initializes the game state.
     */
    function initialize() {
        matchProfileId = RugbyMatchProfiles.getStoredProfileId();
        var activeProfile = RugbyMatchProfiles.getProfile(matchProfileId);
        var activeProfileEntry = MatchProfileEntry.fromDict(activeProfile);
        if (activeProfileEntry == null) {
            activeProfile = RugbyMatchProfiles.getBuiltInProfile("15s");
            activeProfileEntry = MatchProfileEntry.fromDict(activeProfile);
        }
        if (activeProfileEntry != null) {
            matchProfileId = activeProfileEntry.id;
        }

        lockOnStart = Storage.getValue(STORAGE_KEY_LOCK_ON_START);
        if (lockOnStart == null) { lockOnStart = false; }
        resetMatchRuntimeState();

        applyProfile(activeProfile, false);
        
        RugbyTimerPersistence.loadSavedState(self);
    }

    /**
     * Resets all live-match runtime fields while preserving profile/config state.
     *
     * Purpose: provide one canonical initialization/reset path so startup and
     * manual reset do not drift as more state fields are added.
     */
    function resetMatchRuntimeState() {
        gameState = STATE_IDLE;
        homeScore = 0;
        awayScore = 0;
        homeTries = 0;
        awayTries = 0;
        halfNumber = 1;
        gameTime = 0;
        suspensionTime = 0;
        elapsedTime = 0;
        lastUpdate = null;
        gameStartTime = null;
        countdownSeconds = 0;
        countdownRemaining = countdownTimer;
        gpsTrack = [];
        lastEvents = [];
        eventLogEntries = [];
        lastPersistTime = 0;
        yellowHomeTotal = 0;
        yellowAwayTotal = 0;
        redHomeTotal = 0;
        redAwayTotal = 0;
        homePenalties = 0;
        awayPenalties = 0;
        conversionTeam = null;
        pausedState = null;
        yellowHomeTimes = [];
        yellowAwayTimes = [];
        yellowHomeLabelCounter = 0;
        yellowAwayLabelCounter = 0;
        redHomeLabelCounter = 0;
        redAwayLabelCounter = 0;
        redHomeTimes = [];
        redAwayTimes = [];
        redHomePermanent = false;
        redAwayPermanent = false;
        thirtySecondAlerted = false;
        lastPauseReminderTime = null;
        specialAlertTriggered = false;
        conversionStartTime = null;
        penaltyStartTime = null;
        kickoffStartTime = null;
        distance = 0.0;
        speed = 0.0;
        session = null;
        recordingStatusMessage = null;
    }

    function setRecordingStatusMessage(message) {
        recordingStatusMessage = message;
    }

    function consumeRecordingStatusMessage() {
        var message = recordingStatusMessage;
        recordingStatusMessage = null;
        return message;
    }

    /**
     * This method is called periodically to update the game state.
     */
    function updateGame() as Void {
        RugbyTimerTiming.updateGame(self);
    }

    /**
     * Persists the live match snapshot and advances the autosave baseline so
     * the same change is not immediately written again by the periodic timer.
     */
    function persistState() {
        RugbySnapshotService.persistState(self);
    }

    /**
     * Saves any in-progress match state before the app stops and closes the
     * current recording segment cleanly because Connect IQ sessions cannot be
     * resumed after the app process exits.
     */
    function handleAppStop() {
        RugbySnapshotService.handleAppStop(self);
    }

    /**
     * Helper that displays a short M:SS string for cards while hiding zeros.
     * @param seconds The number of seconds to format
     * @return A formatted string in M:SS format
     */
    function formatShortTime(seconds) {
        if (seconds <= 0) {
            return "--";
        }
        var mins = (seconds.toLong() / 60);
        var secs = (seconds.toLong() % 60);
        return mins.toString() + ":" + secs.format("%02d");
    }

    /**
     * Advances the live match clocks to an exact timestamp before a pause or
     * similar transition so every rendered timer freezes on the same boundary.
     */
    function syncLiveClocksToNow(now) {
        if (!(now instanceof Lang.Number) && !(now instanceof Lang.Float)) {
            return;
        }
        if (!(lastUpdate instanceof Lang.Number) && !(lastUpdate instanceof Lang.Float)) {
            lastUpdate = now;
            return;
        }
        var deltaSeconds = (now - lastUpdate) / 1000.0f;
        if (deltaSeconds <= 0) {
            lastUpdate = now;
            return;
        }

        if (gameState != STATE_IDLE && gameState != STATE_ENDED) {
            elapsedTime = elapsedTime + deltaSeconds;
        }

        if (gameState == STATE_PLAYING || gameState == STATE_CONVERSION || gameState == STATE_PENALTY || gameState == STATE_KICKOFF) {
            gameTime = gameTime + deltaSeconds;
            countdownRemaining = countdownTimer - gameTime;
            if (countdownRemaining < 0) { countdownRemaining = 0; }
        }

        if (RugbyTimerTiming.isSuspensionClockRunning(gameState)) {
            suspensionTime = suspensionTime + deltaSeconds;
        }

        if (gameState == STATE_CONVERSION || gameState == STATE_PENALTY) {
            countdownSeconds = countdownSeconds - deltaSeconds;
            if (countdownSeconds < 0) { countdownSeconds = 0; }
        }

        lastUpdate = now;
    }

    /**
     * Called when the match ends or is reset to start fresh state.
     */
    function resetGame() {
        RugbySnapshotService.resetGame(self);
    }

    /**
     * Applies the currently selected profile settings to the active model.
     */
    function applyProfile(profile, persist) {
        var entry = MatchProfileEntry.fromDict(profile);
        if (entry == null) {
            return;
        }
        matchProfileId = entry.id;
        is7s = entry.is7s;
        halfDuration = entry.halfDuration;
        countdownTimer = halfDuration;
        conversionTime = entry.conversionTime;
        kickoffTime = entry.kickoffTime;
        penaltyKickTime = entry.penaltyKickTime;
        useConversionTimer = entry.useConversionTimer;
        usePenaltyTimer = entry.usePenaltyTimer;
        // Always update countdownRemaining to match the new profile timer
        countdownRemaining = countdownTimer;
        if (persist) {
            Storage.setValue(STORAGE_KEY_MATCH_PROFILE_ID, matchProfileId);
            if (matchProfileId == "custom") {
                RugbyMatchProfiles.storeCustomProfile(entry.toDict());
            }
            persistState();
        }
    }

    /**
     * Selects a built-in or custom profile from Settings.
     * @param profileId The profile identifier
     */
    function setMatchProfile(profileId) {
        if (profileId == "custom" && !RugbyMatchProfiles.hasStoredCustomProfile()) {
            saveCurrentSettingsAsCustomProfile();
        }
        applyProfile(RugbyMatchProfiles.getProfile(profileId), true);
    }

    /**
     * Backward-compatible alias for the older 7s/15s toggle.
     * Manual format changes now convert the active preset into the editable custom profile.
     * @param is7sFlag A boolean indicating if the active rules should use 7s-style card behavior
     */
    function setGameType(is7sFlag) {
        setFormatFamily(is7sFlag);
    }

    function setFormatFamily(is7sFlag) {
        promoteToCustomProfile();
        is7s = is7sFlag;
        if (is7s) {
            halfDuration = 420;
            countdownTimer = halfDuration;
            conversionTime = 30;
            kickoffTime = 30;
        } else {
            halfDuration = 2400;
            countdownTimer = halfDuration;
            conversionTime = 90;
            kickoffTime = 60;
        }
        if (gameState == STATE_IDLE) {
            countdownRemaining = countdownTimer;
        }
        saveCurrentSettingsAsCustomProfile();
    }

    /**
     * Overrides the half duration after game type has been set.
     * Saves the custom duration to Storage so it persists across restarts.
     * @param seconds The desired half length in seconds
     */
    function setHalfDuration(seconds) {
        promoteToCustomProfile();
        halfDuration = seconds;
        countdownTimer = seconds;
        if (gameState == STATE_IDLE) {
            countdownRemaining = seconds;
        }
        saveCurrentSettingsAsCustomProfile();
    }

    function setConversionTime(seconds) {
        promoteToCustomProfile();
        conversionTime = seconds;
        saveCurrentSettingsAsCustomProfile();
    }

    function setKickoffTime(seconds) {
        promoteToCustomProfile();
        kickoffTime = seconds;
        saveCurrentSettingsAsCustomProfile();
    }

    function setPenaltyKickTime(seconds) {
        promoteToCustomProfile();
        penaltyKickTime = seconds;
        saveCurrentSettingsAsCustomProfile();
    }

    function setConversionTimerEnabled(enabled) {
        promoteToCustomProfile();
        useConversionTimer = enabled;
        saveCurrentSettingsAsCustomProfile();
    }

    function setPenaltyTimerEnabled(enabled) {
        promoteToCustomProfile();
        usePenaltyTimer = enabled;
        saveCurrentSettingsAsCustomProfile();
    }

    function promoteToCustomProfile() {
        if (matchProfileId != "custom") {
            saveCurrentSettingsAsCustomProfile();
            matchProfileId = "custom";
            Storage.setValue(STORAGE_KEY_MATCH_PROFILE_ID, matchProfileId);
        }
    }

    function saveCurrentSettingsAsCustomProfile() {
        RugbyMatchProfiles.storeCustomProfile(buildCurrentProfile("custom"));
    }

    function buildCurrentProfile(profileId) {
        return RugbyMatchProfiles.createProfile(
            profileId,
            RugbyMatchProfiles.getProfileLabel(profileId),
            is7s,
            countdownTimer,
            conversionTime,
            kickoffTime,
            penaltyKickTime,
            useConversionTimer,
            usePenaltyTimer
        );
    }

    function usesSevensCardRules() {
        return is7s == true || halfDuration == 420 || countdownTimer == 420;
    }

    function getYellowCardDuration() {
        return usesSevensCardRules() ? 120 : 600;
    }

    function getRedCardDuration() {
        // Rugby 15s temporary red cards run for 20 minutes.
        return 1200;
    }

    /**
     * Handles a successful conversion.
     */
    function handleConversionSuccess() {
        if (gameState != STATE_CONVERSION || conversionTeam == null) {
            return;
        }
        recordConversion(conversionTeam);
    }

    /**
     * Handles a missed conversion.
     */
    function handleConversionMiss() {
        if (gameState != STATE_CONVERSION) {
            return;
        }
        if (conversionTeam != null) {
            RugbyTimerEventLog.appendEntry(self, (conversionTeam ? "Home" : "Away") + " Conversion Miss");
        }
        endConversionWithoutScore();
    }

    /**
     * Attempt to resume a persisted match session.
     */
    function saveGame() {
        RugbySnapshotService.saveGame(self);
    }

    /**
     * Kick off the match clock and transition into STATE_PLAYING.
     */
    function startGame() {
        RugbyClockService.startGame(self);
    }

    /**
     * Freeze the countdown timer while leaving gameTime intact.
     */
    function pauseGame() {
        RugbyClockService.pauseGame(self);
    }

    /**
     * Resume play from a paused state.
     */
    function resumeGame() {
        RugbyClockService.resumeGame(self);
    }

    /**
     * Convenience to stop both countdown and special timers for interruptions.
     */
    function pauseClock() {
        RugbyClockService.pauseClock(self);
    }

    /**
     * Resume the countdown and special timers after a pause.
     */
    function resumeClock() {
        RugbyClockService.resumeClock(self);
    }

    /**
     * Continue live play after a conversion/penalty timer finishes.
     */
    function resumePlay() {
        RugbyClockService.resumePlay(self);
    }

    /**
     * Switch state to halftime once first 40 minutes finish.
     */
    function enterHalfTime() {
        RugbyClockService.enterHalfTime(self);
    }

    /**
     * Reset clocks/flags when beginning the second half.
     */
    function startSecondHalf() {
        RugbyClockService.startSecondHalf(self);
    }

    /**
     * Wrap up the match, finalize data, and stop GPS recording.
     */
    function endGame() {
        RugbyClockService.endGame(self);
    }

    /**
     * Score helpers: tries add five points plus conversion clock.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordTry(isHome) {
        RugbyScoringService.recordTry(self, isHome);
    }

    /**
     * Conversion attempt scoring (2 points) triggered by the conversion state.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordConversion(isHome) {
        RugbyScoringService.recordConversion(self, isHome);
    }

    /**
     * Track penalty goals/drops and optionally start a penalty timer.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordPenalty(isHome) {
        RugbyScoringService.recordPenalty(self, isHome);
    }

    /**
     * Drop goal scoring is 3 points without extra timers.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordDropGoal(isHome) {
        RugbyScoringService.recordDropGoal(self, isHome);
    }

    function recordPenaltyTry(isHome) {
        RugbyScoringService.recordPenaltyTry(self, isHome);
    }
    
    /**
     * Add a yellow-card timer entry, tracking its label and vibration state.
     * @param isHome A boolean indicating if the home team received the card
     */
    function recordYellowCard(isHome) {
        RugbyDisciplineService.recordYellowCard(self, isHome);
    }

    /**
     * Handle red cards (permanent for 7s, timed for 15s).
     * @param isHome A boolean indicating if the home team received the card
     */
    function recordRedCard(isHome) {
        RugbyDisciplineService.recordRedCard(self, isHome);
    }
    
    /**
     * Adjust either team’s score with bounds to avoid negative values.
     * @param isHome A boolean indicating if the home team's score should be adjusted
     * @param delta The amount to adjust the score by
     */
    function adjustScore(isHome, delta) {
        if (isHome) {
            homeScore = (homeScore + delta < 0) ? 0 : homeScore + delta;
        } else {
            awayScore = (awayScore + delta < 0) ? 0 : awayScore + delta;
        }
        persistState();
    }
    
    /**
     * Undo mechanism for the last scoring event to support simple corrections.
     * @return true if an event was undone, false otherwise
     */
    function undoLastEvent() {
        return RugbyScoringService.undoLastEvent(self);
    }
    
    /**
     * Keep the event history capped so persistence/storage stays light.
     */
    function trimEvents() {
        RugbyScoringService.trimEvents(self);
    }

    /**
     * Exports the event log to storage.
     */
    function exportEventLog() {
        RugbySnapshotService.exportEventLog(self);
    }

    /**
     * Shows the event log screen.
     */
    function showEventLog() {
        RugbySnapshotService.showEventLog(self);
    }

    /**
     * Begin the conversion timer window when a try is scored.
     */
    function startConversionCountdown() {
        RugbyClockService.startConversionCountdown(self);
    }

    /**
     * Launches the penalty kick countdown display/clock.
     */
    function startPenaltyCountdown() {
        RugbyClockService.startPenaltyCountdown(self);
    }

    /**
     * Cleanly exit a conversion phase when no score is recorded.
     */
    function endConversionWithoutScore() {
        RugbyClockService.endConversionWithoutScore(self);
    }

    /**
     * Begin GPS/activity recording tied to the `SPORT_RUGBY` session.
     */
    function startRecording() {
        RugbyRecordingService.startRecording(self);
    }

    /**
     * Stop the GPS/activity recording safely.
     */
    function stopRecording() {
        RugbyRecordingService.stopRecording(self);
    }

    /**
     * GPS position callback that feeds the activity recording and tracking storyline.
     * @param info The position information
     */
    function updatePosition(info) {
        RugbyRecordingService.updatePosition(self, info);
    }
}
