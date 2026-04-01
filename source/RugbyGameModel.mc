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
 * Represents the data model for the rugby timer application.
 * This class holds the entire state of the game and provides methods to manipulate it.
 * It is the single source of truth for the application's data.
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
    // The total elapsed time in seconds since the game started (always running)
    var elapsedTime;
    // The timestamp of the last update
    var lastUpdate;
    // The timestamp when the game started
    var gameStartTime;
    
    // The current activity recording session
    var session;
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
        if (activeProfile == null) {
            activeProfile = RugbyMatchProfiles.getBuiltInProfile("15s");
            matchProfileId = activeProfile["id"];
        }

        lockOnStart = Storage.getValue("lockOnStart");
        if (lockOnStart == null) { lockOnStart = false; }
        
        gameState = STATE_IDLE;
        homeScore = 0;
        awayScore = 0;
        homeTries = 0;
        awayTries = 0;
        halfNumber = 1;
        gameTime = 0;
        elapsedTime = 0;
        lastUpdate = null;
        gameStartTime = null;
        countdownSeconds = 0;
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
        redHomeTimes = []; redAwayTimes = [];
        redHomePermanent = false; redAwayPermanent = false;
        thirtySecondAlerted = false;
        specialAlertTriggered = false;
        conversionStartTime = null;
        penaltyStartTime = null;
        kickoffStartTime = null;
        
        distance = 0.0;
        speed = 0.0;

        applyProfile(activeProfile, false);
        
        RugbyTimerPersistence.loadSavedState(self);
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
        try {
            RugbyTimerPersistence.saveState(self);
            lastPersistTime = System.getTimer();
        } catch (ex) {
            System.println("Error persisting state");
        }
    }

    /**
     * Saves any in-progress match state before the app stops and closes the
     * current recording segment cleanly because Connect IQ sessions cannot be
     * resumed after the app process exits.
     */
    function handleAppStop() {
        if (gameState != STATE_IDLE && gameState != STATE_ENDED) {
            persistState();
        }
        stopRecording();
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
     * Called when the match ends or is reset to start fresh state.
     */
    function resetGame() {
        stopRecording();
        gameState = STATE_IDLE;
        homeScore = 0;
        awayScore = 0;
        homeTries = 0;
        awayTries = 0;
        halfNumber = 1;
        gameTime = 0;
        elapsedTime = 0;
        countdownRemaining = countdownTimer;
        countdownSeconds = 0;
        gameStartTime = null;
        lastUpdate = null;
        homePenalties = 0;
        awayPenalties = 0;
        lastEvents = [];
        eventLogEntries = [];
        RugbyTimerCards.clearCardTimers(self);
        persistState();
        Storage.setValue("gameStateData", null);
        conversionTeam = null;
    }

    /**
     * Applies the currently selected profile settings to the active model.
     */
    function applyProfile(profile, persist) {
        if (profile == null) {
            return;
        }
        matchProfileId = profile["id"];
        is7s = profile["is7s"] == true;
        halfDuration = profile["halfDuration"];
        countdownTimer = halfDuration;
        conversionTime = profile["conversionTime"];
        kickoffTime = profile["kickoffTime"];
        penaltyKickTime = profile["penaltyKickTime"];
        useConversionTimer = profile["useConversionTimer"] == true;
        usePenaltyTimer = profile["usePenaltyTimer"] == true;
        if (gameState == STATE_IDLE) {
            countdownRemaining = countdownTimer;
        }
        if (persist) {
            Storage.setValue("matchProfileId", matchProfileId);
            if (matchProfileId == "custom") {
                RugbyMatchProfiles.storeCustomProfile(profile);
            }
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
            Storage.setValue("matchProfileId", matchProfileId);
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
        RugbyTimerPersistence.finalizeGameData(self);
        persistState();
    }

    /**
     * Kick off the match clock and transition into STATE_PLAYING.
     */
    function startGame() {
        if (gameState == STATE_IDLE) {
            var now = System.getTimer();
            gameState = STATE_PLAYING;
            yellowHomeTimes = RugbyTimerCards.resumeYellowTimers(yellowHomeTimes, now);
            yellowAwayTimes = RugbyTimerCards.resumeYellowTimers(yellowAwayTimes, now);
            gameStartTime = now;
            lastUpdate = now;
            elapsedTime = 0;
            gameTime = 0;
            countdownRemaining = countdownTimer;  // Reset countdown to configured time
            countdownSeconds = 0;
            thirtySecondAlerted = false;
            startRecording();
            RugbyTimerTiming.triggerMatchStartVibe();
            persistState();
        }
    }

    /**
     * Freeze the countdown timer while leaving gameTime intact.
     */
    function pauseGame() {
        if (gameState == STATE_PLAYING) {
            var now = System.getTimer();
            yellowHomeTimes = RugbyTimerCards.pauseYellowTimers(yellowHomeTimes, now);
            yellowAwayTimes = RugbyTimerCards.pauseYellowTimers(yellowAwayTimes, now);
            redHomeTimes = RugbyTimerCards.pauseYellowTimers(redHomeTimes, now);
            redAwayTimes = RugbyTimerCards.pauseYellowTimers(redAwayTimes, now);
            gameState = STATE_PAUSED;
            // Keep lastUpdate intact so the running game clock keeps progressing while the countdown is paused.
            RugbyTimerTiming.triggerPauseVibe();
            persistState();
        }
    }

    /**
     * Resume play from a paused state.
     */
    function resumeGame() {
        if (gameState == STATE_PAUSED) {
            var now = System.getTimer();
            yellowHomeTimes = RugbyTimerCards.resumeYellowTimers(yellowHomeTimes, now);
            yellowAwayTimes = RugbyTimerCards.resumeYellowTimers(yellowAwayTimes, now);
            redHomeTimes = RugbyTimerCards.resumeYellowTimers(redHomeTimes, now);
            redAwayTimes = RugbyTimerCards.resumeYellowTimers(redAwayTimes, now);
            gameState = STATE_PLAYING;
            lastUpdate = now;
            if (gameStartTime == null) {
                gameStartTime = lastUpdate - (gameTime * 1000.0f);
            }
            RugbyTimerTiming.triggerResumeVibe();
            persistState();
        }
    }

    /**
     * Convenience to stop both countdown and special timers for interruptions.
     */
    function pauseClock() {
        if (gameState != STATE_PAUSED) {
            var now = System.getTimer();
            yellowHomeTimes = RugbyTimerCards.pauseYellowTimers(yellowHomeTimes, now);
            yellowAwayTimes = RugbyTimerCards.pauseYellowTimers(yellowAwayTimes, now);
            redHomeTimes = RugbyTimerCards.pauseYellowTimers(redHomeTimes, now);
            redAwayTimes = RugbyTimerCards.pauseYellowTimers(redAwayTimes, now);
            pausedState = gameState;
            gameState = STATE_PAUSED;
            lastUpdate = null;
            RugbyTimerTiming.triggerPauseVibe();
            persistState();
        }
    }

    /**
     * Resume the countdown and special timers after a pause.
     */
    function resumeClock() {
        if (gameState == STATE_PAUSED) {
            var now = System.getTimer();
            yellowHomeTimes = RugbyTimerCards.resumeYellowTimers(yellowHomeTimes, now);
            yellowAwayTimes = RugbyTimerCards.resumeYellowTimers(yellowAwayTimes, now);
            redHomeTimes = RugbyTimerCards.resumeYellowTimers(redHomeTimes, now);
            redAwayTimes = RugbyTimerCards.resumeYellowTimers(redAwayTimes, now);
            if (pausedState != null) {
                gameState = pausedState;
            } else {
                gameState = STATE_PLAYING;
            }
            pausedState = null;
            lastUpdate = now;
            if (gameStartTime == null) {
                gameStartTime = lastUpdate - (gameTime * 1000.0f);
            }
            // Update individual special timer start times if coming out of a pause into a special state
            if (gameState == STATE_CONVERSION) {
                conversionStartTime = now;
            } else if (gameState == STATE_PENALTY) {
                penaltyStartTime = now;
            }
            if (gameState == STATE_PLAYING || gameState == STATE_CONVERSION || gameState == STATE_PENALTY) {
                startRecording();
            }
            RugbyTimerTiming.triggerResumeVibe();
            persistState();
        }
    }

    /**
     * Continue live play after a conversion/penalty timer finishes.
     */
    function resumePlay() {
        gameState = STATE_PLAYING;
        lastUpdate = System.getTimer();
        startRecording();
        persistState();
    }

    /**
     * Switch state to halftime once first 40 minutes finish.
     */
    function enterHalfTime() {
        gameState = STATE_HALFTIME;
        lastUpdate = null;
        RugbyTimerTiming.triggerHalfTimeVibe();
        persistState();
    }

    /**
     * Reset clocks/flags when beginning the second half.
     */
    function startSecondHalf() {
        if (gameState == STATE_HALFTIME) {
            halfNumber = 2;
            gameTime = 0;
            countdownRemaining = countdownTimer;  // Reset countdown for second half
            gameState = STATE_PLAYING;
            countdownSeconds = 0;
            lastUpdate = System.getTimer();
            startRecording();
            thirtySecondAlerted = false;
            RugbyTimerTiming.triggerMatchStartVibe();
            persistState();
        }
    }

    /**
     * Wrap up the match, finalize data, and stop GPS recording.
     */
    function endGame() {
        gameState = STATE_ENDED;
        lastUpdate = null;
        stopRecording();
        RugbyTimerTiming.triggerFullTimeVibe();
        persistState();
        RugbyTimerPersistence.finalizeGameData(self);
        Storage.setValue("gameStateData", null);
        RugbyTimerCards.clearCardTimers(self);
    }

    /**
     * Score helpers: tries add five points plus conversion clock.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordTry(isHome) {
        if (isHome) {
            homeScore += 5;
            homeTries += 1;
        } else {
            awayScore += 5;
            awayTries += 1;
        }
        lastEvents.add({:type => :try, :home => isHome});
        trimEvents();
        
        // Only start conversion countdown if game is playing
        if (gameState == STATE_PLAYING && useConversionTimer) {
            conversionTeam = isHome;
            startConversionCountdown();
        }
        RugbyTimerEventLog.appendEntry(self, (isHome ? "Home" : "Away") + " Try");
        persistState();
    }

    /**
     * Conversion attempt scoring (2 points) triggered by the conversion state.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordConversion(isHome) {
        if (isHome) {
            homeScore += 2;
        } else {
            awayScore += 2;
        }
        lastEvents.add({:type => :conversion, :home => isHome});
        trimEvents();
        conversionTeam = null;
        RugbyTimerEventLog.appendEntry(self, (isHome ? "Home" : "Away") + " Conversion (made)");
        if (gameState == STATE_CONVERSION) {
            resumePlay();
        } else {
            persistState();
        }
    }

    /**
     * Track penalty goals/drops and optionally start a penalty timer.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordPenalty(isHome) {
        if (isHome) {
            homeScore += 3;
            homePenalties += 1;
        } else {
            awayScore += 3;
            awayPenalties += 1;
        }
        
        lastEvents.add({:type => :penalty, :home => isHome});
        trimEvents();
        
        if (gameState == STATE_PLAYING && usePenaltyTimer) {
            startPenaltyCountdown();
        }
        RugbyTimerEventLog.appendEntry(self, (isHome ? "Home" : "Away") + " Penalty Goal");
        persistState();
    }

    /**
     * Drop goal scoring is 3 points without extra timers.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordDropGoal(isHome) {
        if (isHome) {
            homeScore += 3;
        } else {
            awayScore += 3;
        }
        lastEvents.add({:type => :drop, :home => isHome});
        trimEvents();
        RugbyTimerEventLog.appendEntry(self, (isHome ? "Home" : "Away") + " Drop Goal");
        persistState();
    }

    function recordPenaltyTry(isHome) {
        if (isHome) {
            homeScore += 7;
        } else {
            awayScore += 7;
        }
        lastEvents.add({:type => :penalty_try, :home => isHome});
        trimEvents();
        RugbyTimerEventLog.appendEntry(self, (isHome ? "Home" : "Away") + " Penalty Try");
        persistState();
    }
    
    /**
     * Add a yellow-card timer entry, tracking its label and vibration state.
     * @param isHome A boolean indicating if the home team received the card
     */
    function recordYellowCard(isHome) {
        var duration = getYellowCardDuration();
        var cardId = RugbyTimerCards.allocateYellowCardId(self, isHome);
        var label = "Y" + cardId.toString();
        var entry = RugbyTimerCards.createYellowCardEntryFromStartTime(System.getTimer(), duration, label, cardId);
        if (gameState == STATE_IDLE || gameState == STATE_PAUSED || gameState == STATE_HALFTIME) {
            entry["startTime"] = null;
            entry["remaining"] = duration;
        }
        if (isHome) {
            yellowHomeTimes.add(entry);
            yellowHomeTotal = yellowHomeTotal + 1;
        } else {
            yellowAwayTimes.add(entry);
            yellowAwayTotal = yellowAwayTotal + 1;
        }
        RugbyTimerEventLog.appendEntry(self, (isHome ? "Home" : "Away") + " Yellow Card (" + label + ")");
        persistState();
    }

    /**
     * Handle red cards (permanent for 7s, timed for 15s).
     * @param isHome A boolean indicating if the home team received the card
     */
    function recordRedCard(isHome) {
        var redDuration = getRedCardDuration();
        if (usesSevensCardRules()) {
            if (isHome) {
                redHomePermanent = true;
            } else {
                redAwayPermanent = true;
            }
        } else {
            var entry = RugbyTimerCards.createYellowCardEntryFromStartTime(System.getTimer(), redDuration, "R", 0);
            if (gameState == STATE_IDLE || gameState == STATE_PAUSED || gameState == STATE_HALFTIME) {
                entry["startTime"] = null;
                entry["remaining"] = redDuration;
            }
            if (isHome) {
                redHomeTimes = [entry];
                redHomePermanent = false;
            } else {
                redAwayTimes = [entry];
                redAwayPermanent = false;
            }
        }
        if (isHome) {
            redHomeTotal = redHomeTotal + 1;
        } else {
            redAwayTotal = redAwayTotal + 1;
        }
        RugbyTimerEventLog.appendEntry(self, (isHome ? "Home" : "Away") + " Red Card" + (usesSevensCardRules() ? " (permanent)" : ""));
        persistState();
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
        if (lastEvents.size() == 0) {
            return false;
        }
        var e = lastEvents.remove(lastEvents.size() - 1) as Lang.Dictionary;
        var isHome = e[:home];
        if (e[:type] == :try) {
            if (isHome) {
                homeScore = homeScore - 5;
                if (homeScore < 0) { homeScore = 0; }
                if (homeTries > 0) { homeTries -= 1; }
            } else {
                awayScore = awayScore - 5;
                if (awayScore < 0) { awayScore = 0; }
                if (awayTries > 0) { awayTries -= 1; }
            }
        } else if (e[:type] == :conversion) {
            if (isHome) {
                homeScore = homeScore - 2;
                if (homeScore < 0) { homeScore = 0; }
            } else {
                awayScore = awayScore - 2;
                if (awayScore < 0) { awayScore = 0; }
            }
        } else if (e[:type] == :penalty_try) {
            if (isHome) {
                homeScore = homeScore - 7;
                if (homeScore < 0) { homeScore = 0; }
            } else {
                awayScore = awayScore - 7;
                if (awayScore < 0) { awayScore = 0; }
            }
        } else if (e[:type] == :penalty || e[:type] == :drop) {
            if (isHome) {
                homeScore = homeScore - 3;
                if (homeScore < 0) { homeScore = 0; }
            } else {
                awayScore = awayScore - 3;
                if (awayScore < 0) { awayScore = 0; }
            }
        }
        persistState();
        return true;
    }
    
    /**
     * Keep the event history capped so persistence/storage stays light.
     */
    function trimEvents() {
        if (lastEvents.size() > 20) {
            lastEvents.remove(0);
        }
    }

    /**
     * Exports the event log to storage.
     */
    function exportEventLog() {
        RugbyTimerEventLog.exportEventLog(self);
    }

    /**
     * Shows the event log screen.
     */
    function showEventLog() {
        RugbyTimerEventLog.showEventLog(self);
    }

    /**
     * Begin the conversion timer window when a try is scored.
     */
    function startConversionCountdown() {
        gameState = STATE_CONVERSION;
        countdownSeconds = conversionTime;
        conversionStartTime = System.getTimer();
        specialAlertTriggered = false;
        lastUpdate = System.getTimer();
        RugbyTimerTiming.triggerConversionStartVibe();
    }

    /**
     * Launches the penalty kick countdown display/clock.
     */
    function startPenaltyCountdown() {
        gameState = STATE_PENALTY;
        countdownSeconds = penaltyKickTime;
        penaltyStartTime = System.getTimer();
        specialAlertTriggered = false;
        lastUpdate = System.getTimer();
        RugbyTimerTiming.triggerPenaltyStartVibe();
    }

    /**
     * Cleanly exit a conversion phase when no score is recorded.
     */
    function endConversionWithoutScore() {
        if (gameState == STATE_CONVERSION) {
            conversionTeam = null;
            resumePlay();
        }
    }

    /**
     * Begin GPS/activity recording tied to the `SPORT_RUGBY` session.
     */
    function startRecording() {
        if (!(Toybox has :ActivityRecording)) {
            return;
        }
        try {
            if (session == null) {
                var preferredSport = (Activity has :SPORT_RUGBY) ? Activity.SPORT_RUGBY : Activity.SPORT_GENERIC;
                try {
                    session = ActivityRecording.createSession({
                        :name => "Rugby",
                        :sport => preferredSport
                    });
                } catch (preferredSportEx) {
                    if ((Activity has :SPORT_GENERIC) && preferredSport != Activity.SPORT_GENERIC) {
                        session = ActivityRecording.createSession({
                            :name => "Rugby",
                            :sport => Activity.SPORT_GENERIC
                        });
                    } else {
                        throw preferredSportEx;
                    }
                }
            }
            if (session != null && !session.isRecording()) {
                session.start();
            }
        } catch (ex) {
            System.println("Error starting activity recording: " + ex.getErrorMessage());
            session = null;
        }
    }

    /**
     * Stop the GPS/activity recording safely.
     */
    function stopRecording() {
        if (session == null) {
            return;
        }
        try {
            if (session.isRecording()) {
                session.stop();
            }
            session.save();
        } catch (ex) {
            System.println("Error stopping activity recording: " + ex.getErrorMessage());
        }
        session = null;
    }

    /**
     * GPS position callback that feeds the activity recording and tracking storyline.
     * @param info The position information
     */
    function updatePosition(info) {
        positionInfo = info;
        if (info has :speed && info.speed != null) {
            speed = info.speed;
        }
        if (info has :distance && info.distance != null) {
            distance = info.distance;
        }
        // Collect GPS points for simple breadcrumb trail
        if (info has :position && info.position != null) {
            try {
                var loc = info.position.toDegrees() as Lang.Array;
                gpsTrack.add({:lat => loc[0], :lon => loc[1]});
                if (gpsTrack.size() > MAX_TRACK_POINTS) {
                    gpsTrack.remove(0);
                }
            } catch (ex) {
                System.println("Error converting GPS position: " + ex.getErrorMessage());
            }
        }
    }
}
