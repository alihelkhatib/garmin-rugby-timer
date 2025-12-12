using Toybox.Application.Storage;
using Toybox.System;
using Toybox.ActivityRecording;
using Toybox.Activity;

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
    // The duration of the conversion timer for 7s matches
    var conversionTime7s;
    // The duration of the conversion timer for 15s matches
    var conversionTime15s;
    // The team that is currently attempting a conversion (true for home, false for away)
    var conversionTeam;
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
    // The timer for a red card for the home team
    var redHome;
    // The timer for a red card for the away team
    var redAway;
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
    // The timestamp when the special timer (conversion, penalty) started
    var countdownStartedAt;
    // The initial value of the special timer when it started
    var countdownInitialValue;
    // A flag to ensure the special timer alert is triggered only once
    var specialAlertTriggered;
    
    // The current position information from the GPS
    var positionInfo;
    // The total distance covered during the activity
    var distance;
    // The current speed
    var speed;
    
    // Timers
    const CONVERSION_TIME_15S = 90;  // 90 seconds for 15s
    const CONVERSION_TIME_7S = 30;   // 30 seconds for 7s
    const KICKOFF_TIME = 30;     // 30 seconds for kickoff
    const PENALTY_KICK_TIME = 60; // 60 seconds for penalty kicks
    const MAX_TRACK_POINTS = 200;
    const STATE_SAVE_INTERVAL_MS = 5000;
    
    /**
     * Initializes the game model.
     * Loads settings from storage and initializes the game state.
     */
    function initialize() {
        // Load settings
        var is7sValue = Storage.getValue("rugby7s");
        if (is7sValue == null) {
            is7s = false;
        } else {
            is7s = is7sValue;
        }
        
        halfDuration = is7s ? 420 : 2400; // 7 min or 40 min in seconds
        
        // Load countdown timer setting
        var savedCountdown = Storage.getValue("countdownTimer");
        if (savedCountdown == null) {
            countdownTimer = halfDuration;  // Default to half duration
        } else {
            countdownTimer = savedCountdown;
        }
        
        var ct7 = Storage.getValue("conversionTime7s");
        if (ct7 != null) {
            conversionTime7s = ct7;
        }
        var ct15 = Storage.getValue("conversionTime15s");
        if (ct15 != null) {
            conversionTime15s = ct15;
        }
        var pt = Storage.getValue("penaltyKickTime");
        if (pt != null) {
            penaltyKickTime = pt;
        }
        var useConv = Storage.getValue("useConversionTimer");
        if (useConv != null) {
            useConversionTimer = useConv;
        }
        var usePen = Storage.getValue("usePenaltyTimer");
        if (usePen != null) {
            usePenaltyTimer = usePen;
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
        countdownRemaining = countdownTimer;
        gpsTrack = [];
        lastEvents = [];
        eventLogEntries = [];
        lastPersistTime = 0;
        yellowHomeTotal = 0;
        yellowAwayTotal = 0;
        redHomeTotal = 0;
        redAwayTotal = 0;
        if (conversionTime7s == null) { conversionTime7s = CONVERSION_TIME_7S; }
        if (conversionTime15s == null) { conversionTime15s = CONVERSION_TIME_15S; }
        if (penaltyKickTime == null) { penaltyKickTime = PENALTY_KICK_TIME; }
        if (useConversionTimer == null) { useConversionTimer = true; }
        if (usePenaltyTimer == null) { usePenaltyTimer = true; }
        conversionTeam = null;
        pausedState = null;
        yellowHomeTimes = [];
        yellowAwayTimes = [];
        yellowHomeLabelCounter = 0;
        yellowAwayLabelCounter = 0;
        redHome = 0; redAway = 0;
        redHomePermanent = false; redAwayPermanent = false;
        thirtySecondAlerted = false;
        specialAlertTriggered = false;
        countdownStartedAt = null;
        countdownInitialValue = 0;
        
        distance = 0.0;
        speed = 0.0;
        
        RugbyTimerPersistence.loadSavedState(self);
    }

    /**
     * This method is called periodically to update the game state.
     */
    function updateGame() as Void {
        RugbyTimerTiming.updateGame(self);
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
        lastEvents = [];
        eventLogEntries = [];
        RugbyTimerCards.clearCardTimers(self);
        RugbyTimerPersistence.saveState(self);
        Storage.setValue("gameStateData", null);
        conversionTeam = null;
    }

    /**
     * Updates timers/durations per rugby 7s vs 15s selection.
     * @param is7sFlag A boolean indicating if the game is a 7s match
     */
    function setGameType(is7sFlag) {
        is7s = is7sFlag;
        Storage.setValue("rugby7s", is7sFlag);
        halfDuration = is7s ? 420 : 2400;
        countdownTimer = halfDuration;
        if (gameState == STATE_IDLE) {
            countdownRemaining = countdownTimer;
        }
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
        RugbyTimerPersistence.saveState(self);
    }

    /**
     * Kick off the match clock and transition into STATE_PLAYING.
     */
    function startGame() {
        if (gameState == STATE_IDLE) {
            var now = System.getTimer();
            gameState = STATE_PLAYING;
            gameStartTime = now;
            lastUpdate = now;
            elapsedTime = 0;
            gameTime = 0;
            countdownRemaining = countdownTimer;  // Reset countdown to configured time
            countdownSeconds = 0;
            thirtySecondAlerted = false;
            startRecording();
            RugbyTimerPersistence.saveState(self);
        }
    }

    /**
     * Freeze the countdown timer while leaving gameTime intact.
     */
    function pauseGame() {
        if (gameState == STATE_PLAYING) {
            gameState = STATE_PAUSED;
            // Keep lastUpdate intact so the running game clock keeps progressing while the countdown is paused.
            RugbyTimerPersistence.saveState(self);
        }
    }

    /**
     * Resume play from a paused state.
     */
    function resumeGame() {
        if (gameState == STATE_PAUSED) {
            gameState = STATE_PLAYING;
            lastUpdate = System.getTimer();
            RugbyTimerPersistence.saveState(self);
        }
    }

    /**
     * Convenience to stop both countdown and special timers for interruptions.
     */
    function pauseClock() {
        if (gameState != STATE_PAUSED) {
            pausedState = gameState;
            gameState = STATE_PAUSED;
            lastUpdate = null;
            RugbyTimerPersistence.saveState(self);
        }
    }

    /**
     * Resume the countdown and special timers after a pause.
     */
    function resumeClock() {
        if (gameState == STATE_PAUSED) {
            if (pausedState != null) {
                gameState = pausedState;
            } else {
                gameState = STATE_PLAYING;
            }
            pausedState = null;
            lastUpdate = System.getTimer();
            RugbyTimerPersistence.saveState(self);
        }
    }

    /**
     * Continue live play after a conversion/penalty timer finishes.
     */
    function resumePlay() {
        gameState = STATE_PLAYING;
        lastUpdate = System.getTimer();
        RugbyTimerPersistence.saveState(self);
    }

    /**
     * Switch state to halftime once first 40 minutes finish.
     */
    function enterHalfTime() {
        gameState = STATE_HALFTIME;
        lastUpdate = null;
        RugbyTimerPersistence.saveState(self);
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
            RugbyTimerPersistence.saveState(self);
            thirtySecondAlerted = false;
        }
    }

    /**
     * Wrap up the match, finalize data, and stop GPS recording.
     */
    function endGame() {
        gameState = STATE_ENDED;
        lastUpdate = null;
        stopRecording();
        RugbyTimerPersistence.saveState(self);
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
        if (gameState == STATE_CONVERSION) {
            startKickoffCountdown();
        }
        RugbyTimerEventLog.appendEntry(self, (isHome ? "Home" : "Away") + " Conversion (made)");
    }

    /**
     * Track penalty goals/drops and optionally start a penalty timer.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordPenalty(isHome) {
        if (isHome) {
            homeScore += 3;
        } else {
            awayScore += 3;
        }
        
        lastEvents.add({:type => :penalty, :home => isHome});
        trimEvents();
        
        if (gameState == STATE_PLAYING && usePenaltyTimer) {
            startPenaltyCountdown();
        }
        RugbyTimerEventLog.appendEntry(self, (isHome ? "Home" : "Away") + " Penalty Goal");
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
    }
    
    /**
     * Add a yellow-card timer entry, tracking its label and vibration state.
     * @param isHome A boolean indicating if the home team received the card
     */
    function recordYellowCard(isHome) {
        var duration = is7s ? 120 : 600;
        var cardId = RugbyTimerCards.allocateYellowCardId(self, isHome);
        var label = "Y" + cardId.toString();
        var entry = { "remaining" => duration, "vibeTriggered" => false, "label" => label, "cardId" => cardId };
        if (isHome) {
            yellowHomeTimes.add(entry);
            yellowHomeTotal = yellowHomeTotal + 1;
        } else {
            yellowAwayTimes.add(entry);
            yellowAwayTotal = yellowAwayTotal + 1;
        }
        RugbyTimerEventLog.appendEntry(self, (isHome ? "Home" : "Away") + " Yellow Card (" + label + ")");
    }

    /**
     * Handle red cards (permanent for 7s, timed for 15s).
     * @param isHome A boolean indicating if the home team received the card
     */
    function recordRedCard(isHome) {
        if (is7s) {
            if (isHome) {
                redHomePermanent = true;
                redHome = 0;
            } else {
                redAwayPermanent = true;
                redAway = 0;
            }
        } else {
            var duration = 1200; // 20 minutes
            if (isHome) {
                redHome = duration;
                redHomePermanent = false;
            } else {
                redAway = duration;
                redAwayPermanent = false;
            }
        }
        if (isHome) {
            redHomeTotal = redHomeTotal + 1;
        } else {
            redAwayTotal = redAwayTotal + 1;
        }
        RugbyTimerEventLog.appendEntry(self, (isHome ? "Home" : "Away") + " Red Card" + (is7s ? " (permanent)" : ""));
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
        RugbyTimerPersistence.saveState(self);
    }
    
    /**
     * Undo mechanism for the last scoring event to support simple corrections.
     * @return true if an event was undone, false otherwise
     */
    function undoLastEvent() {
        if (lastEvents.size() == 0) {
            return false;
        }
        var e = lastEvents.remove(lastEvents.size() - 1);
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
        } else if (e[:type] == :penalty || e[:type] == :drop) {
            if (isHome) {
                homeScore = homeScore - 3;
                if (homeScore < 0) { homeScore = 0; }
            } else {
                awayScore = awayScore - 3;
                if (awayScore < 0) { awayScore = 0; }
            }
        }
        RugbyTimerPersistence.saveState(self);
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
        countdownSeconds = is7s ? conversionTime7s : conversionTime15s;
        specialAlertTriggered = false;
        lastUpdate = System.getTimer();
    }

    /**
     * After a conversion attempt ends, prepare the kickoff countdown.
     */
    function startKickoffCountdown() {
        conversionTeam = null;
        gameState = STATE_KICKOFF;
        countdownSeconds = KICKOFF_TIME;
        specialAlertTriggered = false;
        lastUpdate = System.getTimer();
    }

    /**
     * Cancels the kickoff countdown.
     */
    function cancelKickoff() {
        if (gameState == STATE_KICKOFF) {
            countdownSeconds = 0;
            resumePlay();
        }
    }

    /**
     * Launches the penalty kick countdown display/clock.
     */
    function startPenaltyCountdown() {
        gameState = STATE_PENALTY;
        countdownSeconds = penaltyKickTime;
        specialAlertTriggered = false;
        lastUpdate = System.getTimer();
    }

    /**
     * Cleanly exit a conversion phase when no score is recorded.
     */
    function endConversionWithoutScore() {
        if (gameState == STATE_CONVERSION) {
            startKickoffCountdown();
        }
    }

    /**
     * Begin GPS/activity recording tied to the `SPORT_RUGBY` session.
     */
    function startRecording() {
        if (session == null) {
            session = ActivityRecording.createSession({
                :name => "Rugby",
                :sport => Activity.SPORT_RUGBY
            });
            session.start();
        }
    }

    /**
     * Stop the GPS/activity recording safely.
     */
    function stopRecording() {
        if (session != null && session.isRecording()) {
            session.stop();
            session.save();
            session = null;
        }
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
                var loc = info.position.toDegrees();
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
