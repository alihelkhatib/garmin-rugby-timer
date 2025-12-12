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

            // If the game hasn't started, just update lastUpdate and return.
            if (model.gameStartTime == null) {
                model.lastUpdate = newGameTime;
                return;
            }

            // Calculate total elapsed time from the beginning of the game.
            var totalElapsedTimeSeconds = (newGameTime - model.gameStartTime) / 1000.0f;
            
            // Update gameTime based on total elapsed time.
            model.gameTime = totalElapsedTimeSeconds;

            // Keep the previous countdown value for syncing cascade timers.
            var previousCountdownRemaining = model.countdownRemaining;

            // Update countdownRemaining based on total elapsed game time.
            model.countdownRemaining = model.countdownTimer - totalElapsedTimeSeconds;
            if (model.countdownRemaining < 0) { model.countdownRemaining = 0; }
            if (model.countdownRemaining <= 30 && model.countdownRemaining > 0 && !model.thirtySecondAlerted) {
                model.thirtySecondAlerted = true;
                RugbyTimerTiming.triggerThirtySecondVibe();
            }

            if (model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF) {
                // Calculate time elapsed since this special countdown started.
                var timeSinceCountdownStartSeconds = (newGameTime - model.countdownStartedAt) / 1000.0f;
                model.countdownSeconds = model.countdownInitialValue - timeSinceCountdownStartSeconds;

                if (model.countdownSeconds <= 0) {
                    model.countdownSeconds = 0;
                    model.countdownStartedAt = null; // Reset start time for next special timer
                    model.countdownInitialValue = 0; // Reset initial value

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

            // For yellow and red cards, we still use delta for incremental updates.
            // A more robust solution would be to store start times for each individual card.
            // For now, calculate delta based on lastUpdate.
            var countdownDelta = previousCountdownRemaining - model.countdownRemaining;
            if (countdownDelta < 0) {
                countdownDelta = 0;
            }
            var delta = countdownDelta;

            model.yellowHomeTimes = RugbyTimerCards.updateYellowTimers(model, model.yellowHomeTimes, delta);
            model.yellowAwayTimes = RugbyTimerCards.updateYellowTimers(model, model.yellowAwayTimes, delta);
            if (!model.redHomePermanent && model.redHome > 0) { model.redHome = model.redHome - delta; if (model.redHome < 0) { model.redHome = 0; } }
            if (!model.redAwayPermanent && model.redAway > 0) { model.redAway = model.redAway - delta; if (model.redAway < 0) { model.redAway = 0; } }

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
