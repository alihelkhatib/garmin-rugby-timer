using Toybox.Application.Storage;
using Toybox.System;

/**
 * Match-state transition service for the core game clock lifecycle.
 *
 * Purpose: keep start/pause/resume/half/end transitions out of
 * `RugbyGameModel` so the model stays a facade and button/UI layers call one
 * consistent transition surface.
 */
class RugbyClockService {
    static function startGame(model) {
        if (model.gameState == STATE_IDLE) {
            model.flushPendingCustomProfileSave();
            var now = System.getTimer();
            model.gameState = STATE_PLAYING;
            model.gameStartTime = now;
            model.lastUpdate = now;
            model.elapsedTime = 0;
            model.gameTime = 0;
            model.suspensionTime = 0;
            model.countdownRemaining = model.countdownTimer;
            model.countdownSeconds = 0;
            model.thirtySecondAlerted = false;
            RugbyRecordingService.startRecording(model);
            RugbyTimerTiming.triggerMatchStartVibe();
            model.persistState();
        }
    }

    static function pauseGame(model) {
        if (model.gameState == STATE_PLAYING) {
            var now = System.getTimer();
            model.syncLiveClocksToNow(now);
            model.gameState = STATE_PAUSED;
            model.lastPauseReminderTime = now;
            model.lastUpdate = now;
            RugbyTimerTiming.triggerPauseVibe();
            model.persistState();
        }
    }

    static function resumeGame(model) {
        if (model.gameState == STATE_PAUSED) {
            var now = System.getTimer();
            model.gameState = STATE_PLAYING;
            model.lastPauseReminderTime = null;
            model.lastUpdate = now;
            if (model.gameStartTime == null) {
                model.gameStartTime = model.lastUpdate - (model.gameTime * 1000.0f);
            }
            RugbyTimerTiming.triggerResumeVibe();
            model.persistState();
        }
    }

    static function pauseClock(model) {
        if (model.gameState != STATE_PAUSED) {
            var now = System.getTimer();
            model.syncLiveClocksToNow(now);
            model.pausedState = model.gameState;
            model.gameState = STATE_PAUSED;
            model.lastPauseReminderTime = now;
            model.lastUpdate = now;
            RugbyTimerTiming.triggerPauseVibe();
            model.persistState();
        }
    }

    static function resumeClock(model) {
        if (model.gameState == STATE_PAUSED) {
            var now = System.getTimer();
            if (model.pausedState != null) {
                model.gameState = model.pausedState;
            } else {
                model.gameState = STATE_PLAYING;
            }
            model.lastPauseReminderTime = null;
            model.pausedState = null;
            model.lastUpdate = now;
            if (model.gameStartTime == null) {
                model.gameStartTime = model.lastUpdate - (model.gameTime * 1000.0f);
            }
            if (model.gameState == STATE_CONVERSION) {
                model.conversionStartTime = now;
            } else if (model.gameState == STATE_PENALTY) {
                model.penaltyStartTime = now;
            }
            if (model.gameState == STATE_PLAYING || model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY) {
                RugbyRecordingService.startRecording(model);
            }
            RugbyTimerTiming.triggerResumeVibe();
            model.persistState();
        }
    }

    static function resumePlay(model) {
        model.gameState = STATE_PLAYING;
        model.lastPauseReminderTime = null;
        model.lastUpdate = System.getTimer();
        RugbyRecordingService.startRecording(model);
        model.persistState();
    }

    static function enterHalfTime(model) {
        model.gameState = STATE_HALFTIME;
        model.lastPauseReminderTime = null;
        model.lastUpdate = System.getTimer();
        RugbyTimerTiming.triggerHalfTimeVibe();
        model.persistState();
    }

    static function startSecondHalf(model) {
        if (model.gameState == STATE_HALFTIME) {
            model.flushPendingCustomProfileSave();
            model.halfNumber = 2;
            model.gameTime = 0;
            model.countdownRemaining = model.countdownTimer;
            model.gameState = STATE_PLAYING;
            model.lastPauseReminderTime = null;
            model.countdownSeconds = 0;
            model.lastUpdate = System.getTimer();
            RugbyRecordingService.startRecording(model);
            model.thirtySecondAlerted = false;
            RugbyTimerTiming.triggerMatchStartVibe();
            model.persistState();
        }
    }

    static function endGame(model) {
        model.gameState = STATE_ENDED;
        model.lastPauseReminderTime = null;
        model.lastUpdate = null;
        RugbyRecordingService.stopRecording(model);
        RugbyTimerTiming.triggerFullTimeVibe();
        model.persistState();
        RugbySnapshotService.finalizeGame(model);
        RugbyTimerCards.clearCardTimers(model);
    }

    static function startConversionCountdown(model) {
        model.gameState = STATE_CONVERSION;
        model.countdownSeconds = model.conversionTime;
        model.conversionStartTime = System.getTimer();
        model.specialAlertTriggered = false;
        model.lastUpdate = System.getTimer();
        RugbyTimerTiming.triggerConversionStartVibe();
    }

    static function startPenaltyCountdown(model) {
        model.gameState = STATE_PENALTY;
        model.countdownSeconds = model.penaltyKickTime;
        model.penaltyStartTime = System.getTimer();
        model.specialAlertTriggered = false;
        model.lastUpdate = System.getTimer();
        RugbyTimerTiming.triggerPenaltyStartVibe();
    }

    static function endConversionWithoutScore(model) {
        if (model.gameState == STATE_CONVERSION) {
            model.conversionTeam = null;
            RugbyClockService.resumePlay(model);
        }
    }
}
