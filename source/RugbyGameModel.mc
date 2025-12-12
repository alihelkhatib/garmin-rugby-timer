using Toybox.Application.Storage;
using Toybox.System;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.Position;
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
    var gameState as Lang.Number;
    // The score of the home team
    var homeScore as Lang.Number;
    // The score of the away team
    var awayScore as Lang.Number;
    // The number of tries scored by the home team
    var homeTries as Lang.Number;
    // The number of tries scored by the away team
    var awayTries as Lang.Number;
    // The current half number (1 or 2)
    var halfNumber as Lang.Number;
    // The number of seconds for the current countdown (e.g., for conversion, penalty)
    var countdownSeconds as Lang.Float;
    // The main game time in seconds (can be paused)
    var gameTime as Lang.Float;
    // The total elapsed time in seconds since the game started (always running)
    var elapsedTime as Lang.Number;
    // The timestamp of the last update
    var lastUpdate as Lang.Number or Null;
    // The timestamp when the game started
    var gameStartTime as Lang.Number or Null;
    
    // The current activity recording session
    var session as ActivityRecording.Session or Null;
    // A boolean indicating if the game is a 7s or 15s match
    var is7s as Lang.Boolean;
    // The duration of a half in seconds
    var halfDuration as Lang.Number;
    // The configured duration for the main countdown timer
    var countdownTimer as Lang.Number;
    // The remaining time for the main countdown timer
    var countdownRemaining as Lang.Float;
    // An array of GPS track points
    var gpsTrack as Lang.Array;
    // An array of the last scoring events for the undo functionality
    var lastEvents as Lang.Array;
    // An array of all game events for the event log
    var eventLogEntries as Lang.Array;
    // The timestamp of the last time the state was persisted
    var lastPersistTime as Lang.Number;
    // The duration of the conversion timer for 7s matches
    var conversionTime7s as Lang.Number;
    // The duration of the conversion timer for 15s matches
    var conversionTime15s as Lang.Number;
    // The team that is currently attempting a conversion (true for home, false for away)
    var conversionTeam as Lang.Boolean or Null;
    // The duration of the penalty kick timer
    var penaltyKickTime as Lang.Number;
    // A boolean indicating if the conversion timer should be used
    var useConversionTimer as Lang.Boolean;
    // A boolean indicating if the penalty timer should be used
    var usePenaltyTimer as Lang.Boolean;
    // A boolean indicating if the screen should be locked on game start
    var lockOnStart as Lang.Boolean;
    // A flag to ensure the low time alert is triggered only once
    var lowAlertTriggered as Lang.Boolean;
    // A flag to ensure the 30-second alert is triggered only once
    var thirtySecondAlerted as Lang.Boolean;
    // The game state before it was paused
    var pausedState as Lang.Number or Null;
    // An array of timers for yellow cards for the home team
    var yellowHomeTimes as Lang.Array;
    // An array of timers for yellow cards for the away team
    var yellowAwayTimes as Lang.Array;
    // A counter for the labels of yellow cards for the home team
    var yellowHomeLabelCounter as Lang.Number;
    // A counter for the labels of yellow cards for the away team
    var yellowAwayLabelCounter as Lang.Number;
    // The timer for a red card for the home team
    var redHome as Lang.Float;
    // The timer for a red card for the away team
    var redAway as Lang.Float;
    // A boolean indicating if the red card for the home team is permanent
    var redHomePermanent as Lang.Boolean;
    // A boolean indicating if the red card for the away team is permanent
    var redAwayPermanent as Lang.Boolean;
    // The total number of yellow cards for the home team
    var yellowHomeTotal as Lang.Number;
    // The total number of yellow cards for the away team
    var yellowAwayTotal as Lang.Number;
    // The total number of red cards for the home team
    var redHomeTotal as Lang.Number;
    // The total number of red cards for the away team
    var redAwayTotal as Lang.Number;
    // The timestamp when the special timer (conversion, penalty) started
    var countdownStartedAt as Lang.Number or Null;
    // The initial value of the special timer when it started
    var countdownInitialValue as Lang.Float;
    // A flag to ensure the special timer alert is triggered only once
    var specialAlertTriggered as Lang.Boolean;
    
    // The current position information from the GPS
    var positionInfo as Position.Info or Null;
    // The total distance covered during the activity
    var distance as Lang.Float;
    // The current speed
    var speed as Lang.Float;
    
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
        var is7sValue = Storage.getValue("rugby7s") as Lang.Boolean or Null;
        if (is7sValue == null) {
            is7s = false;
        } else {
            is7s = is7sValue;
        }
        
        halfDuration = is7s ? 420 : 2400; // 7 min or 40 min in seconds
        
        // Load countdown timer setting
        var savedCountdown = Storage.getValue("countdownTimer") as Lang.Number or Null;
        if (savedCountdown == null) {
            countdownTimer = halfDuration;  // Default to half duration
        } else {
            countdownTimer = savedCountdown;
        }
        
        var ct7 = Storage.getValue("conversionTime7s") as Lang.Number or Null;
        if (ct7 != null) {
            conversionTime7s = ct7;
        }
        var ct15 = Storage.getValue("conversionTime15s") as Lang.Number or Null;
        if (ct15 != null) {
            conversionTime15s = ct15;
        }
        var pt = Storage.getValue("penaltyKickTime") as Lang.Number or Null;
        if (pt != null) {
            penaltyKickTime = pt;
        }
        var useConv = Storage.getValue("useConversionTimer") as Lang.Boolean or Null;
        if (useConv != null) {
            useConversionTimer = useConv;
        }
        var usePen = Storage.getValue("usePenaltyTimer") as Lang.Boolean or Null;
        if (usePen != null) {
            usePenaltyTimer = usePen;
        }
        var lockOnStartValue = Storage.getValue("lockOnStart") as Lang.Boolean or Null;
        if (lockOnStartValue == null) { lockOnStart = false; } else { lockOnStart = lockOnStartValue; }
        
        gameState = STATE_IDLE;
        homeScore = 0;
        awayScore = 0;
        homeTries = 0;
        awayTries = 0;
        halfNumber = 1;
        gameTime = 0.0f;
        elapsedTime = 0;
        lastUpdate = null;
        gameStartTime = null;
        countdownSeconds = 0.0f;
        countdownRemaining = countdownTimer.toFloat();
        gpsTrack = [] as Array<Dictionary>;
        lastEvents = [] as Array<Dictionary>;
        eventLogEntries = [] as Array<Dictionary>;
        lastPersistTime = 0;
        if (conversionTime7s == null) { conversionTime7s = CONVERSION_TIME_7S; }
        if (conversionTime15s == null) { conversionTime15s = CONVERSION_TIME_15S; }
        if (penaltyKickTime == null) { penaltyKickTime = PENALTY_KICK_TIME; }
        if (useConversionTimer == null) { useConversionTimer = true; }
        if (usePenaltyTimer == null) { usePenaltyTimer = true; }
        conversionTeam = null;
        pausedState = null;
        yellowHomeTimes = [] as Array<Dictionary>;
        yellowAwayTimes = [] as Array<Dictionary>;
        yellowHomeLabelCounter = 0;
        yellowAwayLabelCounter = 0;
        redHome = 0.0f; redAway = 0.0f;
        redHomePermanent = false; redAwayPermanent = false;
        thirtySecondAlerted = false;
        specialAlertTriggered = false;
        countdownStartedAt = null;
        countdownInitialValue = 0.0f;
        
        distance = 0.0f;
        speed = 0.0f;
        
        RugbyTimerPersistence.loadSavedState(self as RugbyGameModel);
    }

    /**
     * This method is called periodically to update the game state.
     */
    function updateGame() as Void {
        RugbyTimerTiming.updateGame(self as RugbyGameModel);
    }

    /**
     * Helper that displays a short M:SS string for cards while hiding zeros.
     * @param seconds The number of seconds to format
     * @return A formatted string in M:SS format
     */
    function formatShortTime(seconds as Lang.Number) as Lang.String {
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
    function resetGame() as Void {
        stopRecording();
        gameState = STATE_IDLE;
        homeScore = 0;
        awayScore = 0;
        homeTries = 0;
        awayTries = 0;
        halfNumber = 1;
        gameTime = 0.0f;
        elapsedTime = 0;
        countdownRemaining = countdownTimer.toFloat();
        countdownSeconds = 0.0f;
        gameStartTime = null;
        lastUpdate = null;
        lastEvents = [] as Array<Dictionary>;
        eventLogEntries = [] as Array<Dictionary>;
        RugbyTimerCards.clearCardTimers(self as RugbyGameModel);
        RugbyTimerPersistence.saveState(self as RugbyGameModel);
        Storage.setValue("gameStateData", null);
        conversionTeam = null;
    }

    /**
     * Updates timers/durations per rugby 7s vs 15s selection.
     * @param is7sFlag A boolean indicating if the game is a 7s match
     */
    function setGameType(is7sFlag as Lang.Boolean) as Void {
        is7s = is7sFlag;
        Storage.setValue("rugby7s", is7sFlag);
        halfDuration = is7s ? 420 : 2400;
        countdownTimer = halfDuration;
        if (gameState == STATE_IDLE) {
            countdownRemaining = countdownTimer.toFloat();
        }
    }

    /**
     * Handles a successful conversion.
     */
    function handleConversionSuccess() as Void {
        if (gameState != STATE_CONVERSION || conversionTeam == null) {
            return;
        }
        recordConversion(conversionTeam as Lang.Boolean);
    }

    /**
     * Handles a missed conversion.
     */
    function handleConversionMiss() as Void {
        if (gameState != STATE_CONVERSION) {
            return;
        }
        if (conversionTeam != null) {
            RugbyTimerEventLog.appendEntry(self as RugbyGameModel, (conversionTeam as Lang.Boolean ? "Home" : "Away") + " Conversion Miss");
        }
        endConversionWithoutScore();
    }

    /**
     * Attempt to resume a persisted match session.
     */
    function saveGame() as Void {
        RugbyTimerPersistence.finalizeGameData(self as RugbyGameModel);
        RugbyTimerPersistence.saveState(self as RugbyGameModel);
    }

    /**
     * Kick off the match clock and transition into STATE_PLAYING.
     */
    function startGame() as Void {
        if (gameState == STATE_IDLE) {
            var now = System.getTimer();
            gameState = STATE_PLAYING;
            gameStartTime = now;
            lastUpdate = now;
            elapsedTime = 0;
            gameTime = 0.0f;
            countdownRemaining = countdownTimer.toFloat();  // Reset countdown to configured time
            countdownSeconds = 0.0f;
            thirtySecondAlerted = false;
            countdownStartedAt = null;
            countdownInitialValue = 0.0f;
            startRecording();
            RugbyTimerPersistence.saveState(self as RugbyGameModel);
        }
    }

    /**
     * Freeze the countdown timer while leaving gameTime intact.
     */
    function pauseGame() as Void {
        if (gameState == STATE_PLAYING) {
            gameState = STATE_PAUSED;
            // Keep lastUpdate intact so the running game clock keeps progressing while the countdown is paused.
            RugbyTimerPersistence.saveState(self as RugbyGameModel);
        }
    }

    /**
     * Resume play from a paused state.
     */
    function resumeGame() as Void {
        if (gameState == STATE_PAUSED) {
            gameState = STATE_PLAYING;
            lastUpdate = System.getTimer();
            RugbyTimerPersistence.saveState(self as RugbyGameModel);
        }
    }

    /**
     * Convenience to stop both countdown and special timers for interruptions.
     */
    function pauseClock() as Void {
        if (gameState != STATE_PAUSED) {
            pausedState = gameState;
            gameState = STATE_PAUSED;
            lastUpdate = null;
            countdownStartedAt = null; // Clear countdown start time when paused
            countdownInitialValue = countdownSeconds; // Store remaining time as initial value
            RugbyTimerPersistence.saveState(self as RugbyGameModel);
        }
    }

    /**
     * Resume the countdown and special timers after a pause.
     */
    function resumeClock() as Void {
        if (gameState == STATE_PAUSED) {
            if (pausedState != null) {
                gameState = pausedState as Lang.Number;
            } else {
                gameState = STATE_PLAYING;
            }
            pausedState = null;
            lastUpdate = System.getTimer();
            countdownStartedAt = System.getTimer(); // Set start time when resumed
            countdownInitialValue = countdownSeconds; // Use current countdownSeconds as initial value
            RugbyTimerPersistence.saveState(self as RugbyGameModel);
        }
    }

    /**
     * Continue live play after a conversion/penalty timer finishes.
     */
    function resumePlay() as Void {
        gameState = STATE_PLAYING;
        lastUpdate = System.getTimer();
        RugbyTimerPersistence.saveState(self as RugbyGameModel);
    }

    /**
     * Switch state to halftime once first 40 minutes finish.
     */
    function enterHalfTime() as Void {
        gameState = STATE_HALFTIME;
        lastUpdate = null;
        RugbyTimerPersistence.saveState(self as RugbyGameModel);
    }

    /**
     * Reset clocks/flags when beginning the second half.
     */
    function startSecondHalf() as Void {
        if (gameState == STATE_HALFTIME) {
            halfNumber = 2;
            gameTime = 0.0f;
            countdownRemaining = countdownTimer.toFloat();  // Reset countdown to configured time
            gameState = STATE_PLAYING;
            countdownSeconds = 0.0f;
            lastUpdate = System.getTimer();
            RugbyTimerPersistence.saveState(self as RugbyGameModel);
            thirtySecondAlerted = false;
        }
    }

    /**
     * Wrap up the match, finalize data, and stop GPS recording.
     */
    function endGame() as Void {
        gameState = STATE_ENDED;
        lastUpdate = null;
        stopRecording();
        RugbyTimerPersistence.saveState(self as RugbyGameModel);
        RugbyTimerPersistence.finalizeGameData(self as RugbyGameModel);
        Storage.setValue("gameStateData", null);
        RugbyTimerCards.clearCardTimers(self as RugbyGameModel);
    }

    /**
     * Score helpers: tries add five points plus conversion clock.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordTry(isHome as Lang.Boolean) as Void {
        if (isHome) {
            homeScore += 5;
            homeTries += 1;
        } else {
            awayScore += 5;
            awayTries += 1;
        }
        lastEvents.add({:type => :try, :home => isHome} as Lang.Dictionary);
        trimEvents();
        
        // Only start conversion countdown if game is playing
        if (gameState == STATE_PLAYING && useConversionTimer) {
            conversionTeam = isHome;
            startConversionCountdown();
        }
        RugbyTimerEventLog.appendEntry(self as RugbyGameModel, (isHome ? "Home" : "Away") + " Try");
    }

    /**
     * Conversion attempt scoring (2 points) triggered by the conversion state.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordConversion(isHome as Lang.Boolean) as Void {
        if (isHome) {
            homeScore += 2;
        } else {
            awayScore += 2;
        }
        lastEvents.add({:type => :conversion, :home => isHome} as Lang.Dictionary);
        trimEvents();
        conversionTeam = null;
        if (gameState == STATE_CONVERSION) {
            startKickoffCountdown();
        }
        RugbyTimerEventLog.appendEntry(self as RugbyGameModel, (isHome ? "Home" : "Away") + " Conversion (made)");
    }

    /**
     * Track penalty goals/drops and optionally start a penalty timer.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordPenalty(isHome as Lang.Boolean) as Void {
        if (isHome) {
            homeScore += 3;
        } else {
            awayScore += 3;
        }
        
        lastEvents.add({:type => :penalty, :home => isHome} as Lang.Dictionary);
        trimEvents();
        
        if (gameState == STATE_PLAYING && usePenaltyTimer) {
            startPenaltyCountdown();
        }
        RugbyTimerEventLog.appendEntry(self as RugbyGameModel, (isHome ? "Home" : "Away") + " Penalty Goal");
    }

    /**
     * Drop goal scoring is 3 points without extra timers.
     * @param isHome A boolean indicating if the home team scored
     */
    function recordDropGoal(isHome as Lang.Boolean) as Void {
        if (isHome) {
            homeScore += 3;
        } else {
            awayScore += 3;
        }
        lastEvents.add({:type => :drop, :home => isHome} as Lang.Dictionary);
        trimEvents();
        RugbyTimerEventLog.appendEntry(self as RugbyGameModel, (isHome ? "Home" : "Away") + " Drop Goal");
    }
    
    /**
     * Add a yellow-card timer entry, tracking its label and vibration state.
     * @param isHome A boolean indicating if the home team received the card
     */
    function recordYellowCard(isHome as Lang.Boolean) as Void {
        var duration = is7s ? 120 : 600;
        var cardId = RugbyTimerCards.allocateYellowCardId(self as RugbyGameModel, isHome) as Lang.Number;
        var label = "Y" + cardId.toString();
        var entry = { "remaining" => duration, "vibeTriggered" => false, "label" => label, "cardId" => cardId } as Lang.Dictionary;
        if (isHome) {
            yellowHomeTimes.add(entry);
            yellowHomeTotal = yellowHomeTotal + 1;
        } else {
            yellowAwayTimes.add(entry);
            yellowAwayTotal = yellowAwayTotal + 1;
        }
        RugbyTimerEventLog.appendEntry(self as RugbyGameModel, (isHome ? "Home" : "Away") + " Yellow Card (" + label + ")");
    }

    /**
     * Handle red cards (permanent for 7s, timed for 15s).
     * @param isHome A boolean indicating if the home team received the card
     */
    function recordRedCard(isHome as Lang.Boolean) as Void {
        if (is7s) {
            if (isHome) {
                redHomePermanent = true;
                redHome = 0.0f;
            } else {
                redAwayPermanent = true;
                redAway = 0.0f;
            }
        } else {
            var duration = 1200; // 20 minutes
            if (isHome) {
                redHome = duration.toFloat();
                redHomePermanent = false;
            } else {
                redAway = duration.toFloat();
                redAwayPermanent = false;
            }
        }
        if (isHome) {
            redHomeTotal = redHomeTotal + 1;
        } else {
            redAwayTotal = redAwayTotal + 1;
        }
        RugbyTimerEventLog.appendEntry(self as RugbyGameModel, (isHome ? "Home" : "Away") + " Red Card" + (is7s ? " (permanent)" : ""));
    }
    
    /**
     * Adjust either team’s score with bounds to avoid negative values.
     * @param isHome A boolean indicating if the home team's score should be adjusted
     * @param delta The amount to adjust the score by
     */
    function adjustScore(isHome as Lang.Boolean, delta as Lang.Number) as Void {
        if (isHome) {
            homeScore = (homeScore + delta < 0) ? 0 : homeScore + delta;
        } else {
            awayScore = (awayScore + delta < 0) ? 0 : awayScore + delta;
        }
        RugbyTimerPersistence.saveState(self as RugbyGameModel);
    }
    
    /**
     * Undo mechanism for the last scoring event to support simple corrections.
     * @return true if an event was undone, false otherwise
     */
    function undoLastEvent() as Boolean {
        if (lastEvents.size() == 0) {
            return false;
        }
        var e = lastEvents.remove(lastEvents.size() - 1) as Lang.Dictionary;
        var isHome = e[:home] as Lang.Boolean;
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
        RugbyTimerPersistence.saveState(self as RugbyGameModel);
        return true;
    }
    
    /**
     * Keep the event history capped so persistence/storage stays light.
     */
    function trimEvents() as Void {
        if (lastEvents.size() > 20) {
            lastEvents.remove(0);
        }
    }

    /**
     * Exports the event log to storage.
     */
    function exportEventLog() as Void {
        RugbyTimerEventLog.exportEventLog(self as RugbyGameModel);
    }

    /**
     * Shows the event log screen.
     */
    function showEventLog() as Void {
        RugbyTimerEventLog.showEventLog(self as RugbyGameModel);
    }

    /**
     * Begin the conversion timer window when a try is scored.
     */
    function startConversionCountdown() as Void {
        gameState = STATE_CONVERSION;
        countdownSeconds = (is7s ? conversionTime7s : conversionTime15s).toFloat();
        countdownStartedAt = System.getTimer();
        countdownInitialValue = countdownSeconds;
        specialAlertTriggered = false;
        lastUpdate = System.getTimer();
    }

    /**
     * After a conversion attempt ends, prepare the kickoff countdown.
     */
    function startKickoffCountdown() as Void {
        conversionTeam = null;
        gameState = STATE_KICKOFF;
        countdownSeconds = KICKOFF_TIME.toFloat();
        countdownStartedAt = System.getTimer();
        countdownInitialValue = KICKOFF_TIME.toFloat();
        specialAlertTriggered = false;
        lastUpdate = System.getTimer();
    }

    /**
     * Cancels the kickoff countdown.
     */
    function cancelKickoff() as Void {
        if (gameState == STATE_KICKOFF) {
            countdownSeconds = 0.0f;
            resumePlay();
        }
    }

    /**
     * Launches the penalty kick countdown display/clock.
     */
    function startPenaltyCountdown() as Void {
        gameState = STATE_PENALTY;
        countdownSeconds = penaltyKickTime.toFloat();
        countdownStartedAt = System.getTimer();
        countdownInitialValue = penaltyKickTime.toFloat();
        specialAlertTriggered = false;
        lastUpdate = System.getTimer();
    }

    /**
     * Cleanly exit a conversion phase when no score is recorded.
     */
    function endConversionWithoutScore() as Void {
        if (gameState == STATE_CONVERSION) {
            startKickoffCountdown();
        }
    }

    /**
     * Begin GPS/activity recording tied to the `SPORT_RUGBY` session.
     */
    function startRecording() as Void {
        if (session == null) {
            session = ActivityRecording.createSession({
                :name => "Rugby",
                :sport => Activity.SPORT_RUGBY
            }) as ActivityRecording.Session;
            session.start();
        }
    }

    /**
     * Stop the GPS/activity recording safely.
     */
    function stopRecording() as Void {
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
    function updatePosition(info as Position.Info) as Void {
        positionInfo = info;
        if (info has :speed && info.speed != null) {
            speed = info.speed as Lang.Float;
        }
        if (info has :distance && info.distance != null) {
            distance = info.distance as Lang.Float;
        }
        // Collect GPS points for simple breadcrumb trail
        if (info has :position && info.position != null) {
            try {
                var loc = info.position.toDegrees() as Array;
                gpsTrack.add({:lat => loc[0], :lon => loc[1]} as Lang.Dictionary);
                if (gpsTrack.size() > MAX_TRACK_POINTS) {
                    gpsTrack.remove(0);
                }
            } catch (ex) {
                System.println("Error converting GPS position: " + ex.getErrorMessage());
            }
        }
    }
}
