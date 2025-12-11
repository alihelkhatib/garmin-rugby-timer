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
}
