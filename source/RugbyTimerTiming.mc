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
    static function updateGame(model as RugbyGameModel) as Void {
        try {
            const newGameTime as Number = System.getTimer();

            // If the game hasn't started, just update lastUpdate and return.
            if (model.gameStartTime == null) {
                model.lastUpdate = newGameTime;
                return;
            }

            // Calculate total elapsed time from the beginning of the game.
            const totalElapsedTimeSeconds as Float = (newGameTime - model.gameStartTime) / 1000.0f;
            
            // Update gameTime based on total elapsed time.
            model.gameTime = totalElapsedTimeSeconds;

            // Update countdownRemaining based on total elapsed game time.
            model.countdownRemaining = model.countdownTimer - totalElapsedTimeSeconds;
            if (model.countdownRemaining < 0) { model.countdownRemaining = 0.0f; }
            if (model.countdownRemaining <= 30 && model.countdownRemaining > 0 && !model.thirtySecondAlerted) {
                model.thirtySecondAlerted = true;
                RugbyTimerTiming.triggerThirtySecondVibe();
            }

            if (model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF) {
                // Calculate time elapsed since this special countdown started.
                const timeSinceCountdownStartSeconds as Float = (newGameTime - (model.countdownStartedAt as Number)) / 1000.0f;
                model.countdownSeconds = (model.countdownInitialValue as Float) - timeSinceCountdownStartSeconds;

                if (model.countdownSeconds <= 0) {
                    model.countdownSeconds = 0.0f;
                    model.countdownStartedAt = null; // Reset start time for next special timer
                    model.countdownInitialValue = 0.0f; // Reset initial value

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
            const delta as Float = (newGameTime - (model.lastUpdate as Number)) / 1000.0f;
            if (delta < 0) {
                delta = 0.0f;
            }

            model.yellowHomeTimes = RugbyTimerCards.updateYellowTimers(model, model.yellowHomeTimes, delta) as Array<Dictionary>;
            model.yellowAwayTimes = RugbyTimerCards.updateYellowTimers(model, model.yellowAwayTimes, delta) as Array<Dictionary>;
            if (!model.redHomePermanent && model.redHome > 0) { model.redHome = model.redHome - delta; if (model.redHome < 0) { model.redHome = 0.0f; } }
            if (!model.redAwayPermanent && model.redAway > 0) { model.redAway = model.redAway - delta; if (model.redAway < 0) { model.redAway = 0.0f; } }

            if (model.countdownRemaining <= 0) {
                model.countdownRemaining = 0.0f;
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
    static function formatTime(seconds as Number) as String {
        if (seconds < 0) {
            seconds = 0;
        }
        var mins = (seconds.toLong() / 60) as Number;
        var secs = (seconds.toLong() % 60) as Number;
        return mins.format("%02d") + ":" + secs.format("%02d");
    }

    /**
     * Triggers a vibration for the 30-second warning.
     */
    static function triggerThirtySecondVibe() as Void {
        if (Attention has :vibrate) {
            var vibeProfiles = [
                new Attention.VibeProfile(50, 500)
            ] as Array<Attention.VibeProfile>;
            Attention.vibrate(vibeProfiles);
        }
    }

    /**
     * Triggers a vibration for the special timer warning.
     */
    static function triggerSpecialTimerVibe() as Void {
        if (Attention has :vibrate) {
            var vibeProfiles = [
                new Attention.VibeProfile(40, 400)
            ] as Array<Attention.VibeProfile>;
            Attention.vibrate(vibeProfiles);
        }
    }

    /**
     * Triggers a vibration for the yellow card timer warning.
     */
    static function triggerYellowTimerVibe() as Void {
        if (Attention has :vibrate) {
            var vibeProfiles = [
                new Attention.VibeProfile(60, 300)
            ] as Array<Attention.VibeProfile>;
            Attention.vibrate(vibeProfiles);
        }
    }
}