using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Timer;
using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Position;
using Toybox.Application.Storage;
using Toybox.System;
using Toybox.Lang;

enum {
    STATE_IDLE,
    STATE_PLAYING,
    STATE_CONVERSION,
    STATE_KICKOFF,
    STATE_HALFTIME,
    STATE_ENDED
}

class RugbyTimerView extends WatchUi.View {
    var gameState;
    var homeScore;
    var awayScore;
    var halfNumber;
    var gameTimer;
    var countdownTimer;
    var countdownSeconds;
    var elapsedTime;
    var lastUpdate;
    
    var session;
    var is7s;
    var halfDuration;
    
    var positionInfo;
    var distance;
    var speed;
    
    var updateTimer;
    
    // Timers
    const CONVERSION_TIME = 90;  // 90 seconds for conversion
    const KICKOFF_TIME = 30;     // 30 seconds for kickoff
    
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
        
        gameState = STATE_IDLE;
        homeScore = 0;
        awayScore = 0;
        halfNumber = 1;
        elapsedTime = 0;
        lastUpdate = null;
        countdownSeconds = 0;
        
        distance = 0.0;
        speed = 0.0;
    }
    
    function onShow() {
        updateTimer = new Timer.Timer();
        updateTimer.start(method(:updateGame), 100, true);
    }



    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Draw scores
        dc.drawText(width / 4, 20, Graphics.FONT_NUMBER_MEDIUM, homeScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(3 * width / 4, 20, Graphics.FONT_NUMBER_MEDIUM, awayScore.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, 20, Graphics.FONT_SMALL, "-", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw game time
        var timeStr = formatTime(elapsedTime);
        dc.drawText(width / 2, 60, Graphics.FONT_MEDIUM, timeStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw half indicator
        var halfStr = "Half " + halfNumber.toString();
        dc.drawText(width / 2, 90, Graphics.FONT_SMALL, halfStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw state-specific info
        if (gameState == STATE_CONVERSION) {
            dc.drawText(width / 2, 120, Graphics.FONT_SMALL, "CONVERSION", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, 145, Graphics.FONT_MEDIUM, countdownSeconds.toString() + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (gameState == STATE_KICKOFF) {
            dc.drawText(width / 2, 120, Graphics.FONT_SMALL, "KICKOFF", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, 145, Graphics.FONT_MEDIUM, countdownSeconds.toString() + "s", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (gameState == STATE_HALFTIME) {
            dc.drawText(width / 2, 120, Graphics.FONT_MEDIUM, "HALF TIME", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (gameState == STATE_ENDED) {
            dc.drawText(width / 2, 120, Graphics.FONT_MEDIUM, "GAME ENDED", Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw GPS and activity info
        if (session != null && session.isRecording()) {
            var distKm = distance / 1000.0;
            var speedKmh = speed * 3.6;
            dc.drawText(width / 2, height - 50, Graphics.FONT_TINY, 
                distKm.format("%.2f") + " km", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, height - 30, Graphics.FONT_TINY, 
                speedKmh.format("%.1f") + " km/h", Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw controls hint
        dc.drawText(width / 2, height - 10, Graphics.FONT_XTINY, 
            "MENU:Settings START:Play", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function updateGame() as Void {
        if (gameState == STATE_PLAYING) {
            var now = System.getTimer();
            if (lastUpdate != null) {
                var delta = (now - lastUpdate) / 1000.0;
                elapsedTime += delta.toNumber();
                
                // Check if half is over
                if (elapsedTime >= halfDuration) {
                    if (halfNumber == 1) {
                        enterHalfTime();
                    } else {
                        endGame();
                    }
                }
            }
            lastUpdate = now;
        } else if (gameState == STATE_CONVERSION || gameState == STATE_KICKOFF) {
            var now = System.getTimer();
            if (lastUpdate != null) {
                var delta = (now - lastUpdate) / 1000.0;
                countdownSeconds -= delta.toNumber();
                
                if (countdownSeconds <= 0) {
                    if (gameState == STATE_CONVERSION) {
                        startKickoffCountdown();
                    } else {
                        resumePlay();
                    }
                }
            }
            lastUpdate = now;
        }
        
        WatchUi.requestUpdate();
    }

    function formatTime(seconds) {
        var mins = seconds / 60;
        var secs = seconds % 60;
        return mins.format("%02d") + ":" + secs.format("%02d");
    }

    function startGame() {
        if (gameState == STATE_IDLE) {
            gameState = STATE_PLAYING;
            lastUpdate = System.getTimer();
            startRecording();
        }
    }

    function pauseGame() {
        if (gameState == STATE_PLAYING) {
            gameState = STATE_IDLE;
            lastUpdate = null;
        }
    }

    function resumePlay() {
        gameState = STATE_PLAYING;
        lastUpdate = System.getTimer();
        WatchUi.requestUpdate();
    }

    function enterHalfTime() {
        gameState = STATE_HALFTIME;
        lastUpdate = null;
        WatchUi.requestUpdate();
    }

    function startSecondHalf() {
        if (gameState == STATE_HALFTIME) {
            halfNumber = 2;
            elapsedTime = 0;
            gameState = STATE_PLAYING;
            lastUpdate = System.getTimer();
        }
    }

    function endGame() {
        gameState = STATE_ENDED;
        lastUpdate = null;
        stopRecording();
        WatchUi.requestUpdate();
    }

    function recordTry(isHome) {
        if (isHome) {
            homeScore += 5;
        } else {
            awayScore += 5;
        }
        startConversionCountdown();
    }

    function recordConversion(isHome) {
        if (isHome) {
            homeScore += 2;
        } else {
            awayScore += 2;
        }
    }

    function recordPenalty(isHome) {
        if (isHome) {
            homeScore += 3;
        } else {
            awayScore += 3;
        }
    }

    function recordDropGoal(isHome) {
        if (isHome) {
            homeScore += 3;
        } else {
            awayScore += 3;
        }
    }

    function startConversionCountdown() {
        gameState = STATE_CONVERSION;
        countdownSeconds = CONVERSION_TIME;
        lastUpdate = System.getTimer();
        WatchUi.requestUpdate();
    }

    function startKickoffCountdown() {
        gameState = STATE_KICKOFF;
        countdownSeconds = KICKOFF_TIME;
        lastUpdate = System.getTimer();
        WatchUi.requestUpdate();
    }

    function startRecording() {
        if (session == null) {
            session = ActivityRecording.createSession({
                :name => "Rugby",
                :sport => Activity.SPORT_RUGBY,
                :subSport => Activity.SUB_SPORT_GENERIC
            });
            session.start();
        }
    }

    function stopRecording() {
        if (session != null && session.isRecording()) {
            session.stop();
            session.save();
            session = null;
        }
    }

    function updatePosition(info) {
        positionInfo = info;
        if (info has :speed && info.speed != null) {
            speed = info.speed;
        }
        if (info has :distance && info.distance != null) {
            distance = info.distance;
        }
    }

    function onHide() {
        if (updateTimer != null) {
            updateTimer.stop();
        }
    }
}