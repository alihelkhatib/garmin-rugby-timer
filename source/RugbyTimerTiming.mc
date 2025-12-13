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
            var newGameTime = System.getTimer();

            if (model.gameState == STATE_PAUSED) {
                model.lastUpdate = newGameTime; // Still update lastUpdate to avoid huge jumps on resume
                return;
            }

            // If the game hasn't started, just update lastUpdate and return.
            if (model.gameStartTime == null) {
                model.lastUpdate = newGameTime;
                return;
            }

            // Calculate total elapsed time from the beginning of the game.
            var totalElapsedTimeSeconds = (newGameTime - model.gameStartTime) / 1000.0f;
            
            // Update gameTime based on total elapsed time.
            model.gameTime = totalElapsedTimeSeconds;

            // Update countdownRemaining based on total elapsed game time.
            model.countdownRemaining = model.countdownTimer - totalElapsedTimeSeconds;
            if (model.countdownRemaining < 0) { model.countdownRemaining = 0; }
            if (model.countdownRemaining <= 30 && model.countdownRemaining > 0 && !model.thirtySecondAlerted) {
                model.thirtySecondAlerted = true;
                RugbyTimerTiming.triggerThirtySecondVibe();
            }

            if (model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF) {
                var initialDuration;
                var startTime;

                if (model.gameState == STATE_CONVERSION) {
                    initialDuration = model.is7s ? model.conversionTime7s : model.conversionTime15s;
                    startTime = model.conversionStartTime;
                } else if (model.gameState == STATE_PENALTY) {
                    initialDuration = model.penaltyKickTime;
                    startTime = model.penaltyStartTime;
                } else { // STATE_KICKOFF
                    initialDuration = model.KICKOFF_TIME;
                    startTime = model.kickoffStartTime;
                }

                if (startTime != null) {
                    var timeSinceCountdownStartSeconds = (newGameTime - startTime) / 1000.0f;
                    model.countdownSeconds = initialDuration - timeSinceCountdownStartSeconds;
                } else {
                    model.countdownSeconds = initialDuration; // Set to initial duration if timer hasn't explicitly started
                }

                if (model.countdownSeconds <= 0) {
                    model.countdownSeconds = 0;
                    // Reset start times for next special timer
                    model.conversionStartTime = null;
                    model.penaltyStartTime = null;
                    model.kickoffStartTime = null;

                    if (model.gameState == STATE_CONVERSION) {
                        model.startKickoffCountdown();
                    } else if (model.gameState == STATE_PENALTY) {
                        model.resumePlay();
                    } else {
                        model.resumePlay();
                    }
                }
                if (model.countdownSeconds <= 15 && model.countdownSeconds > 0 && !model.specialAlertTriggered) {
                    model.specialAlertTriggered = true;
                    RugbyTimerTiming.triggerSpecialTimerVibe();
                }
            }
            
            model.yellowHomeTimes = RugbyTimerCards.updateYellowTimers(model, model.yellowHomeTimes, newGameTime);
            model.yellowAwayTimes = RugbyTimerCards.updateYellowTimers(model, model.yellowAwayTimes, newGameTime);

            // Red card timers
            if (!model.redHomePermanent && model.redHome != null) {
                var redHomeDuration = 1200; // 20 minutes for 15s matches
                var redHomeElapsedTime = (newGameTime - model.redHome) / 1000.0f;
                var redHomeRemaining = redHomeDuration - redHomeElapsedTime;
                if (redHomeRemaining < 0) {
                    model.redHome = null; // Card expired
                }
            }
            if (!model.redAwayPermanent && model.redAway != null) {
                var redAwayDuration = 1200; // 20 minutes for 15s matches
                var redAwayElapsedTime = (newGameTime - model.redAway) / 1000.0f;
                var redAwayRemaining = redAwayDuration - redAwayElapsedTime;
                if (redAwayRemaining < 0) {
                    model.redAway = null; // Card expired
                }
            }

            if (model.countdownRemaining <= 0) {
                model.countdownRemaining = 0;
                if (model.halfNumber == 1) {
                    model.enterHalfTime();
                } else {
                    model.endGame();
                }
            }

            model.lastUpdate = newGameTime;
            if (model.lastPersistTime == 0 || newGameTime - model.lastPersistTime > model.STATE_SAVE_INTERVAL_MS) {
                RugbyTimerPersistence.saveState(model);
                model.lastPersistTime = newGameTime;
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
