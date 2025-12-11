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
    static function updateGame(model) as Void {
        try {
            var now = System.getTimer();
            if (model.gameStartTime != null) {
                model.elapsedTime = (now - model.gameStartTime) / 1000;
            }

            var delta = 0;
            if (model.lastUpdate != null) {
                delta = (now - model.lastUpdate) / 1000.0;
                if (delta < 0) {
                    delta = 0;
                }
            }
            if (delta > 0 && model.gameState != STATE_IDLE && model.gameState != STATE_ENDED) {
                model.gameTime = model.gameTime + delta;
            }

            if (model.gameState == STATE_PLAYING || model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF) {
                model.countdownRemaining = model.countdownRemaining - delta;
                if (model.countdownRemaining < 0) { model.countdownRemaining = 0; }
                if (model.countdownRemaining <= 30 && model.countdownRemaining > 0 && !model.thirtySecondAlerted) {
                    model.thirtySecondAlerted = true;
                    RugbyTimerTiming.triggerThirtySecondVibe();
                }

                if (model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF) {
                    model.countdownSeconds = model.countdownSeconds - delta;
                    if (model.countdownSeconds <= 0) {
                        model.countdownSeconds = 0;
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
            }

            model.lastUpdate = now;
            if (model.lastPersistTime == 0 || now - model.lastPersistTime > model.STATE_SAVE_INTERVAL_MS) {
                RugbyTimerPersistence.saveState(model);
                model.lastPersistTime = now;
            }

        } catch (ex) {
            // Silently handle errors to prevent crash
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