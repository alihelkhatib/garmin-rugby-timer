using Toybox.Application.Storage;
using Toybox.System;
using Toybox.ActivityRecording;
using Toybox.Activity;

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

class RugbyGameModel {
    var gameState;
    var homeScore;
    var awayScore;
    var homeTries;
    var awayTries;
    var halfNumber;
    var countdownSeconds;
    var gameTime;  // Game time (can be paused)
    var elapsedTime;  // Total elapsed time (always running)
    var lastUpdate;
    var gameStartTime;  // When the game/session actually started
    
    var session;
    var is7s;
    var halfDuration;
    var countdownTimer;  // New: countdown timer
    var countdownRemaining;  // New: remaining countdown time
    var gpsTrack;
    var lastEvents;
    var eventLogEntries;
    var lastPersistTime;
    var conversionTime7s;
    var conversionTime15s;
    var conversionTeam; // Holds which team currently has the conversion attempt (true=home, false=away)
    var penaltyKickTime;
    var useConversionTimer;
    var usePenaltyTimer;
    var lockOnStart;
    var lowAlertTriggered;
    var thirtySecondAlerted;
    var pausedState;
    var yellowHomeTimes;
    var yellowAwayTimes;
    var yellowHomeLabelCounter;
    var yellowAwayLabelCounter;
    var redHome;
    var redAway;
    var redHomePermanent;
    var redAwayPermanent;
    var yellowHomeTotal;
    var yellowAwayTotal;
    var redHomeTotal;
    var redAwayTotal;
    var specialAlertTriggered;
    
    var positionInfo;
    var distance;
    var speed;
    
    // Timers
    const CONVERSION_TIME_15S = 90;  // 90 seconds for 15s
    const CONVERSION_TIME_7S = 30;   // 30 seconds for 7s
    const KICKOFF_TIME = 30;     // 30 seconds for kickoff
    const PENALTY_KICK_TIME = 60; // 60 seconds for penalty kicks
    const MAX_TRACK_POINTS = 200;
    const STATE_SAVE_INTERVAL_MS = 5000;
    
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
        
        distance = 0.0;
        speed = 0.0;
        
        RugbyTimerPersistence.loadSavedState(self);
    }

    function updateGame() as Void {
        RugbyTimerTiming.updateGame(self);
    }

    // Helper that displays a short M:SS string for cards while hiding zeros.
    function formatShortTime(seconds) {
        if (seconds <= 0) {
            return "--";
        }
        var mins = (seconds.toLong() / 60);
        var secs = (seconds.toLong() % 60);
        return mins.toString() + ":" + secs.format("%02d");
    }

    // Called when the match ends or is reset to start fresh state.
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

    // Updates timers/durations per rugby 7s vs 15s selection.
    function setGameType(is7sFlag) {
        is7s = is7sFlag;
        Storage.setValue("rugby7s", is7sFlag);
        halfDuration = is7s ? 420 : 2400;
        countdownTimer = halfDuration;
        if (gameState == STATE_IDLE) {
            countdownRemaining = countdownTimer;
        }
    }

    function handleConversionSuccess() {
        if (gameState != STATE_CONVERSION || conversionTeam == null) {
            return;
        }
        recordConversion(conversionTeam);
    }

    function handleConversionMiss() {
        if (gameState != STATE_CONVERSION) {
            return;
        }
        if (conversionTeam != null) {
            RugbyTimerEventLog.appendEntry(self, (conversionTeam ? "Home" : "Away") + " Conversion Miss");
        }
        endConversionWithoutScore();
    }

    // Attempt to resume a persisted match session.
    function saveGame() {
        RugbyTimerPersistence.finalizeGameData(self);
        RugbyTimerPersistence.saveState(self);
    }

    // Kick off the match clock and transition into STATE_PLAYING.
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

    // Freeze the countdown timer while leaving gameTime intact.
    function pauseGame() {
        if (gameState == STATE_PLAYING) {
            gameState = STATE_PAUSED;
            // Keep lastUpdate intact so the running game clock keeps progressing while the countdown is paused.
            RugbyTimerPersistence.saveState(self);
        }
    }

    // Resume play from a paused state.
    function resumeGame() {
        if (gameState == STATE_PAUSED) {
            gameState = STATE_PLAYING;
            lastUpdate = System.getTimer();
            RugbyTimerPersistence.saveState(self);
        }
    }

    // Convenience to stop both countdown and special timers for interruptions.
    function pauseClock() {
        if (gameState != STATE_PAUSED) {
            pausedState = gameState;
            gameState = STATE_PAUSED;
            lastUpdate = null;
            RugbyTimerPersistence.saveState(self);
        }
    }

    // Resume the countdown and special timers after a pause.
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

    // Continue live play after a conversion/penalty timer finishes.
    function resumePlay() {
        gameState = STATE_PLAYING;
        lastUpdate = System.getTimer();
        RugbyTimerPersistence.saveState(self);
    }

    // Switch state to halftime once first 40 minutes finish.
    function enterHalfTime() {
        gameState = STATE_HALFTIME;
        lastUpdate = null;
        RugbyTimerPersistence.saveState(self);
    }

    // Reset clocks/flags when beginning the second half.
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

    // Wrap up the match, finalize data, and stop GPS recording.
    function endGame() {
        gameState = STATE_ENDED;
        lastUpdate = null;
        stopRecording();
        RugbyTimerPersistence.saveState(self);
        RugbyTimerPersistence.finalizeGameData(self);
        Storage.setValue("gameStateData", null);
        RugbyTimerCards.clearCardTimers(self);
    }

    // Score helpers: tries add five points plus conversion clock.
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

    // Conversion attempt scoring (2 points) triggered by the conversion state.
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

    // Track penalty goals/drops and optionally start a penalty timer.
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

    // Drop goal scoring is 3 points without extra timers.
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
    
    // Add a yellow-card timer entry, tracking its label and vibration state.
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

    // Handle red cards (permanent for 7s, timed for 15s).
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
    
    // Adjust either team’s score with bounds to avoid negative values.
    function adjustScore(isHome, delta) {
        if (isHome) {
            homeScore = (homeScore + delta < 0) ? 0 : homeScore + delta;
        } else {
            awayScore = (awayScore + delta < 0) ? 0 : awayScore + delta;
        }
        RugbyTimerPersistence.saveState(self);
    }
    
    // Undo mechanism for the last scoring event to support simple corrections.
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
    
    // Keep the event history capped so persistence/storage stays light.
    function trimEvents() {
        if (lastEvents.size() > 20) {
            lastEvents.remove(0);
        }
    }

    function exportEventLog() {
        RugbyTimerEventLog.exportEventLog(self);
    }

    function showEventLog() {
        RugbyTimerEventLog.showEventLog(self);
    }

    // Begin the conversion timer window when a try is scored.
    function startConversionCountdown() {
        gameState = STATE_CONVERSION;
        countdownSeconds = is7s ? conversionTime7s : conversionTime15s;
        specialAlertTriggered = false;
        lastUpdate = System.getTimer();
    }

    // After a conversion attempt ends, prepare the kickoff countdown.
    function startKickoffCountdown() {
        conversionTeam = null;
        gameState = STATE_KICKOFF;
        countdownSeconds = KICKOFF_TIME;
        specialAlertTriggered = false;
        lastUpdate = System.getTimer();
    }

    function cancelKickoff() {
        if (gameState == STATE_KICKOFF) {
            countdownSeconds = 0;
            resumePlay();
        }
    }

    // Launches the penalty kick countdown display/clock.
    function startPenaltyCountdown() {
        gameState = STATE_PENALTY;
        countdownSeconds = penaltyKickTime;
        specialAlertTriggered = false;
        lastUpdate = System.getTimer();
    }

    // Cleanly exit a conversion phase when no score is recorded.
    function endConversionWithoutScore() {
        if (gameState == STATE_CONVERSION) {
            startKickoffCountdown();
        }
    }

    // Begin GPS/activity recording tied to the `SPORT_RUGBY` session.
    function startRecording() {
        if (session == null) {
            session = ActivityRecording.createSession({
                :name => "Rugby",
                :sport => Activity.SPORT_RUGBY
            });
            session.start();
        }
    }

    // Stop the GPS/activity recording safely.
    function stopRecording() {
        if (session != null && session.isRecording()) {
            session.stop();
            session.save();
            session = null;
        }
    }

    // GPS position callback that feeds the activity recording and tracking storyline.
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
                // ignore conversion errors
            }
        }
    }
}
