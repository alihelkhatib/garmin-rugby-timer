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
    static function clearSpecialTimerState(model) {
        model.countdownSeconds = 0;
        model.conversionStartTime = null;
        model.penaltyStartTime = null;
        model.kickoffStartTime = null;
        model.specialAlertTriggered = false;
        model.conversionTeam = null;
    }

    static function startGame(model) {
        if (model.gameState == STATE_IDLE) {
            var now = System.getTimer();
            model.gameState = STATE_PLAYING;
            model.gameStartTime = now;
            model.lastUpdate = now;
            model.elapsedTime = 0;
            model.gameTime = 0;
            model.suspensionTime = 0;
            model.countdownRemaining = model.countdownTimer;
            RugbyClockService.clearSpecialTimerState(model);
            model.pausedState = null;
            model.thirtySecondAlerted = false;
            RugbyRecordingService.startRecording(model);
            RugbyTimerTiming.triggerMatchStartVibe();
            RugbySnapshotService.persistState(model);
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
            RugbySnapshotService.persistState(model);
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
            RugbySnapshotService.persistState(model);
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
            RugbySnapshotService.persistState(model);
        }
    }

    static function resumeClock(model) {
        if (model.gameState == STATE_PAUSED) {
            var now = System.getTimer();
            model.gameState = RugbyMatchStateSupport.getResumeState(model.pausedState);
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
            if (RugbyMatchStateSupport.shouldStartRecordingForState(model.gameState)) {
                RugbyRecordingService.startRecording(model);
            }
            RugbyTimerTiming.triggerResumeVibe();
            RugbySnapshotService.persistState(model);
        }
    }

    static function resumePlay(model) {
        model.gameState = STATE_PLAYING;
        model.lastPauseReminderTime = null;
        model.lastUpdate = System.getTimer();
        RugbyClockService.clearSpecialTimerState(model);
        model.pausedState = null;
        RugbyRecordingService.startRecording(model);
        RugbySnapshotService.persistState(model);
    }

    static function enterHalfTime(model) {
        var now = System.getTimer();
        model.gameState = STATE_HALFTIME;
        model.lastPauseReminderTime = null;
        RugbyClockService.clearSpecialTimerState(model);
        model.countdownSeconds = model.kickoffTime;
        model.pausedState = null;
        model.lastUpdate = now;
        RugbyTimerTiming.triggerHalfTimeVibe();
        RugbySnapshotService.persistState(model);
    }

    static function startSecondHalf(model) {
        if (model.gameState == STATE_HALFTIME) {
            model.halfNumber = 2;
            model.gameTime = 0;
            model.countdownRemaining = model.countdownTimer;
            model.gameState = STATE_PLAYING;
            model.lastPauseReminderTime = null;
            RugbyClockService.clearSpecialTimerState(model);
            model.lastUpdate = System.getTimer();
            RugbyRecordingService.startRecording(model);
            model.pausedState = null;
            model.thirtySecondAlerted = false;
            RugbyTimerTiming.triggerMatchStartVibe();
            RugbySnapshotService.persistState(model);
        }
    }

    static function adjustHalfTimeBreak(model, deltaMinutes) {
        if (model.gameState != STATE_HALFTIME) {
            return;
        }
        var nextBreakSeconds = RugbyTimerInputSupport.getAdjustedBreakSeconds(model.countdownSeconds, deltaMinutes);
        model.setKickoffTime(nextBreakSeconds);
        model.countdownSeconds = nextBreakSeconds;
        if (nextBreakSeconds <= 0) {
            RugbyClockService.prepareSecondHalfReady(model);
            return;
        }
        model.lastUpdate = System.getTimer();
        RugbySnapshotService.persistState(model);
    }

    static function prepareSecondHalfReady(model) {
        if (model.gameState != STATE_HALFTIME) {
            return;
        }
        RugbyClockService.clearSpecialTimerState(model);
        model.gameTime = 0;
        model.countdownRemaining = model.countdownTimer;
        model.thirtySecondAlerted = false;
        model.pausedState = null;
        model.lastUpdate = System.getTimer();
        RugbySnapshotService.persistState(model);
    }

    static function endGame(model) {
        model.gameState = STATE_ENDED;
        model.lastPauseReminderTime = null;
        RugbyClockService.clearSpecialTimerState(model);
        model.pausedState = null;
        model.lastUpdate = null;
        RugbyRecordingService.stopRecording(model);
        RugbyTimerTiming.triggerFullTimeVibe();
        RugbySnapshotService.persistState(model);
        RugbySnapshotService.finalizeGame(model);
        RugbyTimerCards.clearCardTimers(model);
    }

    static function startConversionCountdown(model) {
        var now = System.getTimer();
        model.syncLiveClocksToNow(now);
        RugbyClockService.clearSpecialTimerState(model);
        model.gameState = STATE_CONVERSION;
        model.countdownSeconds = model.conversionTime;
        model.conversionStartTime = now;
        model.lastUpdate = now;
        RugbyTimerTiming.triggerConversionStartVibe();
    }

    static function startPenaltyCountdown(model) {
        var now = System.getTimer();
        model.syncLiveClocksToNow(now);
        RugbyClockService.clearSpecialTimerState(model);
        model.gameState = STATE_PENALTY;
        model.countdownSeconds = model.penaltyKickTime;
        model.penaltyStartTime = now;
        model.lastUpdate = now;
        RugbyTimerTiming.triggerPenaltyStartVibe();
    }

    static function endConversionWithoutScore(model) {
        if (model.gameState == STATE_CONVERSION) {
            model.conversionTeam = null;
            RugbyClockService.resumePlay(model);
        }
    }
}
