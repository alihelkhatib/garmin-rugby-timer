using Toybox.Attention;
using Toybox.System;
using Toybox.WatchUi;

/**
 * A helper class for handling game timing.
 */
class RugbyTimerTiming {
    /**
     * This method is called periodically to update the game state.
     * @param model The game model
     */
    static function updateGame(model) {
        try {
            var now = System.getTimer();

            if (model.gameStartTime == null) {
                model.lastUpdate = now;
                return;
            }

            if (model.lastUpdate == null) {
                model.lastUpdate = now;
                return;
            }

            // Always derive gameTime from absolute start so it never stops during pauses.
            model.gameTime = (now - model.gameStartTime) / 1000.0f;

            var deltaSeconds = (now - model.lastUpdate) / 1000.0f;
            if (deltaSeconds < 0) { deltaSeconds = 0; }

            var timersPaused = (model.gameState == STATE_PAUSED);

            // Countdown only ticks during active states
            if (!timersPaused && (model.gameState == STATE_PLAYING || model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF)) {
                model.countdownRemaining = model.countdownRemaining - deltaSeconds;
                if (model.countdownRemaining < 0) { model.countdownRemaining = 0; }
                if (model.countdownRemaining <= 30 && model.countdownRemaining > 0 && !model.thirtySecondAlerted) {
                    model.thirtySecondAlerted = true;
                    RugbyTimerTiming.triggerThirtySecondVibe();
                }
            }

            // Special timers tick only when active and not paused
            if (!timersPaused && (model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF)) {
                model.countdownSeconds = model.countdownSeconds - deltaSeconds;
                if (model.countdownSeconds < 0) { model.countdownSeconds = 0; }

                if (model.countdownSeconds <= 0) {
                    model.countdownSeconds = 0;
                    model.conversionStartTime = null;
                    model.penaltyStartTime = null;
                    model.kickoffStartTime = null;

                    if (model.gameState == STATE_CONVERSION) {
                        model.startKickoffCountdown();
                    } else {
                        model.resumePlay();
                    }
                } else if (model.countdownSeconds <= 15 && !model.specialAlertTriggered) {
                    model.specialAlertTriggered = true;
                    RugbyTimerTiming.triggerSpecialTimerVibe();
                }
            }
            
            if (!timersPaused) {
                model.yellowHomeTimes = RugbyTimerCards.updateYellowTimers(model, model.yellowHomeTimes, now);
                model.yellowAwayTimes = RugbyTimerCards.updateYellowTimers(model, model.yellowAwayTimes, now);

                // Red card timers
                if (!model.redHomePermanent && model.redHome != null) {
                    var redHomeDuration = 1200; // 20 minutes for 15s matches
                    var redHomeElapsedTime = (now - model.redHome) / 1000.0f;
                    var redHomeRemaining = redHomeDuration - redHomeElapsedTime;
                    if (redHomeRemaining < 0) {
                        model.redHome = null; // Card expired
                    }
                }
                if (!model.redAwayPermanent && model.redAway != null) {
                    var redAwayDuration = 1200; // 20 minutes for 15s matches
                    var redAwayElapsedTime = (now - model.redAway) / 1000.0f;
                    var redAwayRemaining = redAwayDuration - redAwayElapsedTime;
                    if (redAwayRemaining < 0) {
                        model.redAway = null; // Card expired
                    }
                }
            }

            if (!timersPaused && model.countdownRemaining <= 0) {
                model.countdownRemaining = 0;
                if (model.halfNumber == 1) {
                    model.enterHalfTime();
                } else {
                    model.endGame();
                }
            }

            model.lastUpdate = now;
            if (model.lastPersistTime == 0 || now - model.lastPersistTime > model.STATE_SAVE_INTERVAL_MS) {
                RugbyTimerPersistence.saveState(model);
                model.lastPersistTime = now;
            }

        } catch (ex) {
            System.println("Error in RugbyTimerTiming.updateGame: " + ex.getErrorMessage());
        }
    }

    /**
     * Formats a time in seconds into a MM:SS string.
     * @param seconds The time in seconds
     * @return The formatted time string
     */
    static function formatTime(seconds) {
        if (seconds < 0) {
            seconds = 0;
        }
        var mins = (seconds.toLong() / 60);
        var secs = (seconds.toLong() % 60);
        return mins.format("%02d") + ":" + secs.format("%02d");
    }

    /**
     * Triggers a vibration for the 30-second warning.
     */
    static function triggerThirtySecondVibe() {
        if (Attention has :vibrate) {
            var vibeProfiles = [
                new Attention.VibeProfile(50, 500)
            ];
            Attention.vibrate(vibeProfiles);
        }
    }

    /**
     * Triggers a vibration for the special timer warning.
     */
    static function triggerSpecialTimerVibe() {
        if (Attention has :vibrate) {
            var vibeProfiles = [
                new Attention.VibeProfile(40, 400)
            ];
            Attention.vibrate(vibeProfiles);
        }
    }

    /**
     * Triggers a vibration for the yellow card timer warning.
     */
    static function triggerYellowTimerVibe() {
        if (Attention has :vibrate) {
            var vibeProfiles = [
                new Attention.VibeProfile(60, 300)
            ];
            Attention.vibrate(vibeProfiles);
        }
    }
}
