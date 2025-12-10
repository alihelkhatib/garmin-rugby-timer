using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Timer;
using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Position;
using Toybox.Application.Storage;
using Toybox.System;
using Toybox.Lang;
using Toybox.Attention;

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

class RugbyTimerView extends WatchUi.View {
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
    var promptedGameType;
    var gpsTrack;
    var lastEvents;
    var isLocked;
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
    var dimMode;
    var lastActionTs;
    var pausedState;
    var yellowHomeTimes;
    var yellowAwayTimes;
    var yellowHomeLabelCounter;
    var yellowAwayLabelCounter;
    var redHome;
    var redAway;
    var redHomePermanent;
    var redAwayPermanent;
    
    var positionInfo;
    var distance;
    var speed;
    
    var updateTimer;
    
    // Timers
    const CONVERSION_TIME_15S = 90;  // 90 seconds for 15s
    const CONVERSION_TIME_7S = 30;   // 30 seconds for 7s
    const KICKOFF_TIME = 30;     // 30 seconds for kickoff
    const PENALTY_KICK_TIME = 60; // 60 seconds for penalty kicks
    const MAX_TRACK_POINTS = 200;
    const STATE_SAVE_INTERVAL_MS = 5000;
    
    // Primary initialization: load persisted settings, zero all counters, and prepare timers.
    function initialize() {
        View.initialize();
        
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
        dimMode = Storage.getValue("dimMode");
        if (dimMode == null) { dimMode = false; }
        
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
        promptedGameType = false;
        gpsTrack = [];
        lastEvents = [];
        isLocked = false;
        lastPersistTime = 0;
        if (conversionTime7s == null) { conversionTime7s = CONVERSION_TIME_7S; }
        if (conversionTime15s == null) { conversionTime15s = CONVERSION_TIME_15S; }
        if (penaltyKickTime == null) { penaltyKickTime = PENALTY_KICK_TIME; }
        if (useConversionTimer == null) { useConversionTimer = true; }
        if (usePenaltyTimer == null) { usePenaltyTimer = true; }
        lastActionTs = 0;
        conversionTeam = null;
        pausedState = null;
        yellowHomeTimes = [];
        yellowAwayTimes = [];
        yellowHomeLabelCounter = 0;
        yellowAwayLabelCounter = 0;
        redHome = 0; redAway = 0;
        redHomePermanent = false; redAwayPermanent = false;
        thirtySecondAlerted = false;
        
        distance = 0.0;
        speed = 0.0;
        
        loadSavedState();
    }

    // Layout callback needed by WatchUi; just delegates to the main layout definition.
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Display callback: begin the periodic update loop and prompt for game type once on screen.
    function onShow() {
        if (updateTimer == null) {
            updateTimer = new Timer.Timer();
            updateTimer.start(method(:updateGame), 100, true);
        }
        
        if (!promptedGameType && gameState == STATE_IDLE) {
            promptedGameType = true;
            showGameTypePrompt();
        }
    }

    // Simple debounce for adjustments/quick actions
    // Simple debounce gate to prevent rapid repeated actions from hardware buttons.
    function isActionAllowed() {
        var now = System.getTimer();
        if (lastActionTs == null || now - lastActionTs > 300) {
            lastActionTs = now;
            return true;
        }
        return false;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Choose fonts based on resolution so things stay readable without overlap
        var scoreFont;
        var triesFont;
        var halfFont;
        var timerFont;
        var gameTimerFont;
        var stateFont;
        var hintFont;
        if (width <= 240) { // 6S
            scoreFont = Graphics.FONT_NUMBER_MEDIUM;
            triesFont = Graphics.FONT_XTINY;
            halfFont = Graphics.FONT_XTINY;
            timerFont = Graphics.FONT_SYSTEM_TINY;
            countdownFont = Graphics.FONT_NUMBER_HOT;
            stateFont = Graphics.FONT_SMALL;
            hintFont = Graphics.FONT_XTINY;
        } else if (width <= 260) { // 6 / 6 Pro
            scoreFont = Graphics.FONT_NUMBER_MEDIUM;
            triesFont = Graphics.FONT_XTINY;
            halfFont = Graphics.FONT_XTINY;
            timerFont = Graphics.FONT_SYSTEM_TINY;
            countdownFont = Graphics.FONT_NUMBER_HOT;
            stateFont = Graphics.FONT_SMALL;
            hintFont = Graphics.FONT_XTINY;
        } else { // 6X
            scoreFont = Graphics.FONT_NUMBER_MEDIUM;
            triesFont = Graphics.FONT_SMALL;
            halfFont = Graphics.FONT_XTINY;
            timerFont = Graphics.FONT_SYSTEM_TINY;
            countdownFont = Graphics.FONT_NUMBER_HOT;
            stateFont = Graphics.FONT_SMALL;
            hintFont = Graphics.FONT_XTINY;
        }
        
        // Relative Y positions (fractions of screen height)
        var scoreY = height * 0.10;
        var halfY = height * 0.18;
        var gameTimerY = halfY - height * 0.04; // place the ongoing game clock just above the “Half #” label
        if (gameTimerY < scoreY + height * 0.02) {
            gameTimerY = scoreY + height * 0.02;
        }
        var triesY = halfY + height * 0.06;
        var cardsY = height * 0.37;
        var timerY = height * 0.48; // baseline position where the countdown timer starts before any cards shift it
        var countdownY = height * 0.66; // default lower slot for the bonus timer display
        var stateY = height * 0.82;
        var hintY = height * 0.92;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Scores
        dc.drawText(width / 4, scoreY, scoreFont, homeScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(3 * width / 4, scoreY, scoreFont, awayScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        // Game timer above the half indicator so referees see elapsed game minutes near the center top.
        var gameStr = formatTime(gameTime);
        dc.drawText(width / 2, gameTimerY, timerFont, gameStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Half indicator
        var halfStr = "Half " + halfNumber.toString();
        dc.drawText(width / 2, halfY, halfFont, halfStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Tries
        var triesText = homeTries.toString() + "T / " + awayTries.toString() + "T";
        dc.drawText(width / 2, triesY, triesFont, triesText, Graphics.TEXT_JUSTIFY_CENTER);

        // Lock indicator
        if (isLocked) {
            dc.drawText(width - (width * 0.1).toLong(), scoreY, halfFont, "L", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Card status line (only show if active/permanent)
        var visibleYellowHome = yellowHomeTimes.size() > 2 ? 2 : yellowHomeTimes.size();
        var visibleYellowAway = yellowAwayTimes.size() > 2 ? 2 : yellowAwayTimes.size();
        var homeCardRows = visibleYellowHome + ((redHome > 0 || redHomePermanent) ? 1 : 0);
        var awayCardRows = visibleYellowAway + ((redAway > 0 || redAwayPermanent) ? 1 : 0);
        var maxCardRows = (homeCardRows > awayCardRows) ? homeCardRows : awayCardRows;
        if (maxCardRows > 0) {
            var homeLine = 0;
            var awayLine = 0;
            var lineStep = height * 0.1;
            var cardFont = Graphics.FONT_MEDIUM;
            var homeYellowDisplayed = 0;
            for (var i = 0; i < yellowHomeTimes.size() && homeYellowDisplayed < 2; i = i + 1) {
                var entry = yellowHomeTimes[i];
                var y = entry["remaining"];
                var label = entry["label"];
                if (label == null) {
                    label = "Y" + (homeYellowDisplayed + 1).toString();
                }
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 4, cardsY + homeLine * lineStep, cardFont, label + ":" + formatShortTime(y), Graphics.TEXT_JUSTIFY_CENTER);
                homeLine += 1;
                homeYellowDisplayed += 1;
            }
            var awayYellowDisplayed = 0;
            for (var i = 0; i < yellowAwayTimes.size() && awayYellowDisplayed < 2; i = i + 1) {
                var entry = yellowAwayTimes[i];
                var y = entry["remaining"];
                var label = entry["label"];
                if (label == null) {
                    label = "Y" + (awayYellowDisplayed + 1).toString();
                }
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(3 * width / 4, cardsY + awayLine * lineStep, cardFont, label + ":" + formatShortTime(y), Graphics.TEXT_JUSTIFY_CENTER);
                awayLine += 1;
                awayYellowDisplayed += 1;
            }
            if (redHome > 0 || redHomePermanent) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 4, cardsY + homeLine * lineStep, cardFont, redHomePermanent ? "R:PERM" : "R:" + formatShortTime(redHome), Graphics.TEXT_JUSTIFY_CENTER);
                homeLine += 1;
            }
            if (redAway > 0 || redAwayPermanent) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(3 * width / 4, cardsY + awayLine * lineStep, cardFont, redAwayPermanent ? "R:PERM" : "R:" + formatShortTime(redAway), Graphics.TEXT_JUSTIFY_CENTER);
                awayLine += 1;
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var cardAreaBottom = cardsY + maxCardRows * lineStep;
            // Raise the main timer just below the card stack if cards extend upward; candidateTimerY tracks that offset.
            var candidateTimerY = cardAreaBottom + height * 0.06;
            var timerLimit = (stateY - height * 0.3);
            timerY = (height * 0.48 > candidateTimerY) ? height * 0.48 : candidateTimerY;
            timerY = (timerY < timerLimit) ? timerY : timerLimit;
            var countdownCandidate = timerY + height * 0.2; // keep the game timer below the primary countdown block
            var countdownLimit = stateY - height * 0.12;
            countdownY = (countdownCandidate < countdownLimit) ? countdownCandidate : countdownLimit;
        }
        
        // Countdown timer (primary)
        var countdownStr = formatTime(countdownRemaining);
        dc.drawText(width / 2, countdownY, countdownFont, countdownStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // State/status block
        if (gameState == STATE_PAUSED) {
            dc.drawText(width / 2, stateY, stateFont, "PAUSED", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (gameState == STATE_CONVERSION) {
            dc.drawText(width / 2, stateY, stateFont, "CONVERSION", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, countdownSeconds.toLong().toString() + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (gameState == STATE_PENALTY) {
            dc.drawText(width / 2, stateY, stateFont, "PENALTY KICK", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, countdownSeconds.toLong().toString() + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (gameState == STATE_KICKOFF) {
            dc.drawText(width / 2, stateY, stateFont, "KICKOFF", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, stateY + (height * 0.07), stateFont, countdownSeconds.toLong().toString() + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (gameState == STATE_HALFTIME) {
            dc.drawText(width / 2, stateY, stateFont, "HALF TIME", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (gameState == STATE_ENDED) {
            dc.drawText(width / 2, stateY, stateFont, "GAME ENDED", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (gameState == STATE_IDLE) {
            dc.drawText(width / 2, stateY, stateFont, "Ready to start", Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Hint
        var hint = "";
        if (gameState == STATE_IDLE) {
            hint = "SELECT: Start";
        } else if (gameState == STATE_PLAYING) {
            hint = "SELECT: Pause";
        } else if (gameState == STATE_PAUSED) {
            hint = "SELECT: Resume";
        }
        if (isLocked) {
            hint = "LOCKED";
        }
        var hintColor = dimMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE;
        dc.setColor(hintColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, hintY, hintFont, hint, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Periodic tick that keeps the clocks, card timers, and persistence in sync.
    function updateGame() as Void {
        try {
            var now = System.getTimer();
            
            // Always update elapsed time if game has started
        if (gameStartTime != null) {
            elapsedTime = (now - gameStartTime) / 1000;
        }

        // Update game time and countdown timer when playing or during set-piece timers
        var delta = 0;
        if (lastUpdate != null) {
            delta = (now - lastUpdate) / 1000.0;
            if (delta < 0) {
                delta = 0;
            }
        }
        if (delta > 0 && gameState != STATE_IDLE && gameState != STATE_ENDED) {
            gameTime = gameTime + delta;
        }

        if (gameState == STATE_PLAYING || gameState == STATE_CONVERSION || gameState == STATE_PENALTY) {
            countdownRemaining = countdownRemaining - delta;
            if (countdownRemaining < 0) { countdownRemaining = 0; }
            if (countdownRemaining <= 30 && countdownRemaining > 0 && !thirtySecondAlerted) {
                thirtySecondAlerted = true;
                triggerThirtySecondVibe();
            }

            if (gameState == STATE_CONVERSION || gameState == STATE_PENALTY) {
                countdownSeconds = countdownSeconds - delta;
                if (countdownSeconds <= 0) {
                    countdownSeconds = 0;
                    if (gameState == STATE_CONVERSION) {
                        startKickoffCountdown();
                    } else {
                        resumePlay();
                    }
                }
            }

            yellowHomeTimes = updateYellowTimers(yellowHomeTimes, delta);
            yellowAwayTimes = updateYellowTimers(yellowAwayTimes, delta);
            if (!redHomePermanent && redHome > 0) { redHome = redHome - delta; if (redHome < 0) { redHome = 0; } }
            if (!redAwayPermanent && redAway > 0) { redAway = redAway - delta; if (redAway < 0) { redAway = 0; } }

            if (countdownRemaining <= 0) {
                countdownRemaining = 0;
                if (halfNumber == 1) {
                    enterHalfTime();
                } else {
                    endGame();
                }
            }
        } else if (gameState == STATE_KICKOFF) {
            countdownSeconds = countdownSeconds - delta;
            if (countdownSeconds < 0) { countdownSeconds = 0; }

            if (countdownSeconds <= 0) {
                countdownSeconds = 0;
                resumePlay();
            }
        }
        lastUpdate = now;
            
            if (lastPersistTime == 0 || now - lastPersistTime > STATE_SAVE_INTERVAL_MS) {
                saveState();
                lastPersistTime = now;
            }
            
            WatchUi.requestUpdate();
        } catch (ex) {
            // Silently handle errors to prevent crash
        }
    }

    // Convert raw seconds into a zero-padded MM:SS string for display.
    function formatTime(seconds) {
        if (seconds < 0) {
            seconds = 0;
        }
        var mins = (seconds.toLong() / 60);
        var secs = (seconds.toLong() % 60);
        return mins.format("%02d") + ":" + secs.format("%02d");
    }

    // Plays the thirty-second warning haptic when the countdown drops below 30s.
    function triggerThirtySecondVibe() {
        if (Attention has :vibrate) {
            var vibeProfiles = [
                new Attention.VibeProfile(50, 500)
            ];
            Attention.vibrate(vibeProfiles);
        }
    }
    
    // Alerts the referee when a yellow timer is about to expire (below 10s).
    function triggerYellowTimerVibe() {
        if (Attention has :vibrate) {
            var vibeProfiles = [
                new Attention.VibeProfile(40, 300)
            ];
            Attention.vibrate(vibeProfiles);
        }
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

    // Tick and prune yellow timers; hidden entries still count down in the background.
    function updateYellowTimers(list, delta) {
        var newList = [];
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i];
            var remaining = entry["remaining"] - delta;
            var vibTriggered = entry["vibeTriggered"];
            var label = entry["label"];
            if (remaining <= 0) {
                continue;
            }
            if (!vibTriggered && remaining <= 10) {
                vibTriggered = true;
                triggerYellowTimerVibe();
            }
            newList.add({ "remaining" => remaining, "vibeTriggered" => vibTriggered, "label" => label });
        }
        return newList;
    }

    // Guard when reading saved state so each timer has both remaining time and label metadata.
    function normalizeYellowTimers(list) {
        var normalized = [];
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i];
            if (entry == null) {
                continue;
            }
            var remaining = null;
            var vibTriggered = false;
            var label = null;
            try {
                remaining = entry["remaining"];
                vibTriggered = entry["vibeTriggered"];
                label = entry["label"];
            } catch (ex) {
                remaining = entry;
            }
            if (remaining == null) {
                continue;
            }
            normalized.add({ "remaining" => remaining, "vibeTriggered" => vibTriggered, "label" => label });
        }
        return normalized;
    }

    // Track the highest yellow label seen so new cards keep their sequential numbering.
    function computeYellowLabelCounter(list) {
        var maxLabel = 0;
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i];
            if (entry == null) {
                continue;
            }
            var label = null;
            try {
                label = entry["label"];
            } catch (ex) {
                label = null;
            }
            if (label == null) {
                continue;
            }
            var labelNumber = parseLabelNumber(label);
            if (labelNumber > maxLabel) {
                maxLabel = labelNumber;
            }
        }
        return maxLabel;
    }

    // Parse the numeric portion of a label like “Y3” so counters increment safely.
    function parseLabelNumber(label) {
        if (label == null) {
            return 0;
        }
        var digits = label;
        if (digits.length() > 0 && digits[0] == "Y") {
            var trimmed = "";
            for (var idx = 1; idx < digits.length(); idx = idx + 1) {
                trimmed = trimmed + digits[idx];
            }
            digits = trimmed;
        }
        if (digits.length() == 0) {
            return 0;
        }
        try {
            return digits.toLong();
        } catch (ex) {
            return 0;
        }
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
        saveState();
        Storage.setValue("gameStateData", null);
        WatchUi.requestUpdate();
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

    // Presents the menu asking whether the match is 7s or 15s.
    function showGameTypePrompt() {
        WatchUi.pushView(new GameTypeMenu(), new GameTypePromptDelegate(self), WatchUi.SLIDE_UP);
    }

    // Launches the score dialog stack; respects the locked state.
    function showScoreDialog() {
        if (isLocked) {
            return;
        }
        WatchUi.pushView(new ScoreTeamMenu(), new ScoreTeamDelegate(self), WatchUi.SLIDE_UP);
    }

    // Launches the card/discipline dialog (swap button assigned externally).
    function showCardDialog() {
        if (isLocked) {
            return;
        }
        WatchUi.pushView(new CardTeamMenu(), new CardTeamDelegate(self), WatchUi.SLIDE_UP);
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
        endConversionWithoutScore();
    }

    // Attempt to resume a persisted match session.
    function loadSavedState() {
        var data = Storage.getValue("gameStateData") as Lang.Dictionary;
        if (data != null) {
            try {
                homeScore = data["homeScore"];
                awayScore = data["awayScore"];
                homeTries = data["homeTries"];
                awayTries = data["awayTries"];
                halfNumber = data["halfNumber"];
                gameTime = data["gameTime"];
                elapsedTime = data["elapsedTime"];
                countdownRemaining = data["countdownRemaining"];
                countdownSeconds = data["countdownSeconds"];
                gameState = data["gameState"];
                is7s = data["is7s"];
                countdownTimer = data["countdownTimer"];
                conversionTime7s = data["conversionTime7s"];
                conversionTime15s = data["conversionTime15s"];
                penaltyKickTime = data["penaltyKickTime"];
                useConversionTimer = data["useConversionTimer"];
                usePenaltyTimer = data["usePenaltyTimer"];
                var savedConversion = data["conversionTeam"];
                conversionTeam = savedConversion;
                var yHomeArr = data["yellowHomeTimes"];
                  if (yHomeArr != null) {
                      yellowHomeTimes = normalizeYellowTimers(yHomeArr);
                  } else {
                      yellowHomeTimes = [];
                  }
                  yellowHomeLabelCounter = computeYellowLabelCounter(yellowHomeTimes);
                  var savedHomeLabelCounter = data["yellowHomeLabelCounter"];
                  if (savedHomeLabelCounter != null && savedHomeLabelCounter > yellowHomeLabelCounter) {
                      yellowHomeLabelCounter = savedHomeLabelCounter;
                  }
                  var yAwayArr = data["yellowAwayTimes"];
                  if (yAwayArr != null) {
                      yellowAwayTimes = normalizeYellowTimers(yAwayArr);
                  } else {
                      yellowAwayTimes = [];
                  }
                  yellowAwayLabelCounter = computeYellowLabelCounter(yellowAwayTimes);
                  var savedAwayLabelCounter = data["yellowAwayLabelCounter"];
                  if (savedAwayLabelCounter != null && savedAwayLabelCounter > yellowAwayLabelCounter) {
                      yellowAwayLabelCounter = savedAwayLabelCounter;
                  }
                redHome = data["redHome"];
                if (redHome == null) { redHome = 0; }
                redAway = data["redAway"];
                if (redAway == null) { redAway = 0; }
                redHomePermanent = data["redHomePermanent"];
                if (redHomePermanent == null) { redHomePermanent = false; }
                redAwayPermanent = data["redAwayPermanent"];
                if (redAwayPermanent == null) { redAwayPermanent = false; }
                // Resume safely: if it was playing, return paused
                if (gameState == STATE_PLAYING || gameState == STATE_CONVERSION || gameState == STATE_PENALTY || gameState == STATE_KICKOFF) {
                    gameState = STATE_PAUSED;
                }
            } catch (ex) {
                // ignore corrupted state
            }
        }
    }

    // Persist all derived game/session values so restart can pick them up.
    function saveState() {
        var snapshot = {
            "homeScore" => homeScore,
            "awayScore" => awayScore,
            "homeTries" => homeTries,
            "awayTries" => awayTries,
            "halfNumber" => halfNumber,
            "gameTime" => gameTime,
            "elapsedTime" => elapsedTime,
            "countdownRemaining" => countdownRemaining,
            "countdownSeconds" => countdownSeconds,
            "gameState" => gameState,
            "is7s" => is7s,
            "countdownTimer" => countdownTimer,
            "conversionTime7s" => conversionTime7s,
            "conversionTime15s" => conversionTime15s,
            "penaltyKickTime" => penaltyKickTime,
            "useConversionTimer" => useConversionTimer,
            "usePenaltyTimer" => usePenaltyTimer,
            "conversionTeam" => conversionTeam,
            "yellowHomeTimes" => yellowHomeTimes,
            "yellowAwayTimes" => yellowAwayTimes,
            "yellowHomeLabelCounter" => yellowHomeLabelCounter,
            "yellowAwayLabelCounter" => yellowAwayLabelCounter,
            "redHome" => redHome,
            "redAway" => redAway,
            "redHomePermanent" => redHomePermanent,
            "redAwayPermanent" => redAwayPermanent
        };
        Storage.setValue("gameStateData", snapshot);
    }

    // Capture the final match summary before exiting the session.
    function finalizeGameData() {
        var summary = {
            "homeScore" => homeScore,
            "awayScore" => awayScore,
            "homeTries" => homeTries,
            "awayTries" => awayTries,
            "halfNumber" => halfNumber,
            "elapsedTime" => elapsedTime,
            "countdownRemaining" => countdownRemaining,
            "yellowHomeTimes" => yellowHomeTimes,
            "yellowAwayTimes" => yellowAwayTimes,
            "redHome" => redHome,
            "redAway" => redAway,
            "redHomePermanent" => redHomePermanent,
            "redAwayPermanent" => redAwayPermanent
        };
        Storage.setValue("lastGameSummary", summary);
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
            saveState();
            if (lockOnStart) {
                isLocked = true;
            }
            WatchUi.requestUpdate();
        }
    }

    // Freeze the countdown timer while leaving gameTime intact.
    function pauseGame() {
        if (gameState == STATE_PLAYING) {
            gameState = STATE_PAUSED;
            lastUpdate = null;
            saveState();
        }
    }

    // Resume play from a paused state.
    function resumeGame() {
        if (gameState == STATE_PAUSED) {
            gameState = STATE_PLAYING;
            lastUpdate = System.getTimer();
            saveState();
        }
    }

    // Convenience to stop both countdown and special timers for interruptions.
    function pauseClock() {
        if (gameState != STATE_PAUSED) {
            pausedState = gameState;
            gameState = STATE_PAUSED;
            lastUpdate = null;
            saveState();
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
            saveState();
        }
    }

    // Continue live play after a conversion/penalty timer finishes.
    function resumePlay() {
        gameState = STATE_PLAYING;
        lastUpdate = System.getTimer();
        saveState();
        WatchUi.requestUpdate();
    }

    // Switch state to halftime once first 40 minutes finish.
    function enterHalfTime() {
        gameState = STATE_HALFTIME;
        lastUpdate = null;
        saveState();
        WatchUi.requestUpdate();
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
            saveState();
            thirtySecondAlerted = false;
        }
    }

    // Wrap up the match, finalize data, and stop GPS recording.
    function endGame() {
        gameState = STATE_ENDED;
        lastUpdate = null;
        stopRecording();
        saveState();
        finalizeGameData();
        Storage.setValue("gameStateData", null);
        WatchUi.requestUpdate();
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
        WatchUi.requestUpdate();
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
        WatchUi.requestUpdate();
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
        WatchUi.requestUpdate();
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
        WatchUi.requestUpdate();
    }
    
    // Add a yellow-card timer entry, tracking its label and vibration state.
    function recordYellowCard(isHome) {
        var duration = is7s ? 120 : 600;
        if (isHome) {
            yellowHomeLabelCounter += 1;
            var label = "Y" + yellowHomeLabelCounter.toString();
            yellowHomeTimes.add({ "remaining" => duration, "vibeTriggered" => false, "label" => label });
        } else {
            yellowAwayLabelCounter += 1;
            var label = "Y" + yellowAwayLabelCounter.toString();
            yellowAwayTimes.add({ "remaining" => duration, "vibeTriggered" => false, "label" => label });
        }
        WatchUi.requestUpdate();
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
        WatchUi.requestUpdate();
    }
    
    // Adjust either team’s score with bounds to avoid negative values.
    function adjustScore(isHome, delta) {
        if (isHome) {
            homeScore = (homeScore + delta < 0) ? 0 : homeScore + delta;
        } else {
            awayScore = (awayScore + delta < 0) ? 0 : awayScore + delta;
        }
        saveState();
        WatchUi.requestUpdate();
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
        saveState();
        WatchUi.requestUpdate();
        return true;
    }
    
    // Keep the event history capped so persistence/storage stays light.
    function trimEvents() {
        if (lastEvents.size() > 20) {
            lastEvents.remove(0);
        }
    }

    // Begin the conversion timer window when a try is scored.
    function startConversionCountdown() {
        gameState = STATE_CONVERSION;
        countdownSeconds = is7s ? conversionTime7s : conversionTime15s;
        lastUpdate = System.getTimer();
        WatchUi.requestUpdate();
    }

    // After a conversion attempt ends, prepare the kickoff countdown.
    function startKickoffCountdown() {
        conversionTeam = null;
        gameState = STATE_KICKOFF;
        countdownSeconds = KICKOFF_TIME;
        lastUpdate = System.getTimer();
        WatchUi.requestUpdate();
    }

    // Launches the penalty kick countdown display/clock.
    function startPenaltyCountdown() {
        gameState = STATE_PENALTY;
        countdownSeconds = penaltyKickTime;
        lastUpdate = System.getTimer();
        WatchUi.requestUpdate();
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

    // Lock/unlock the UI so accidental button presses can't change state.
    function toggleLock() {
        isLocked = !isLocked;
        WatchUi.requestUpdate();
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

    // Clean up resources when the view is hidden.
    function onHide() {
        if (updateTimer != null) {
            updateTimer.stop();
            updateTimer = null;
        }
    }
}
