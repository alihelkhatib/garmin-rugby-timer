using Toybox.Attention;
using Toybox.System;
using Toybox.WatchUi;

/**
 * A helper class for handling game timing.
 */
class RugbyTimerTiming {
    const HALF_WARNING_SECONDS = 30;
    const SPECIAL_WARNING_SECONDS = 10;

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
            if (!timersPaused && (model.gameState == STATE_PLAYING || model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY)) {
                model.countdownRemaining = model.countdownRemaining - deltaSeconds;
                if (model.countdownRemaining < 0) { model.countdownRemaining = 0; }
                if (model.countdownRemaining <= 30 && model.countdownRemaining > 0 && !model.thirtySecondAlerted) {
                    model.thirtySecondAlerted = true;
                    RugbyTimerTiming.triggerHalfEndingSoonVibe();
                }
            }

            // Special timers tick only when active and not paused
            if (!timersPaused && (model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY)) {
                var specialState = model.gameState;
                model.countdownSeconds = model.countdownSeconds - deltaSeconds;
                if (model.countdownSeconds < 0) { model.countdownSeconds = 0; }

                if (model.countdownSeconds <= 0) {
                    if (specialState == STATE_CONVERSION) {
                        RugbyTimerTiming.triggerConversionExpiredVibe();
                    } else {
                        RugbyTimerTiming.triggerPenaltyExpiredVibe();
                    }
                    model.countdownSeconds = 0;
                    model.conversionStartTime = null;
                    model.penaltyStartTime = null;
                    model.kickoffStartTime = null;
                    model.resumePlay();
                } else if (model.countdownSeconds <= 10 && !model.specialAlertTriggered) {
                    model.specialAlertTriggered = true;
                    if (specialState == STATE_CONVERSION) {
                        RugbyTimerTiming.triggerConversionWarningVibe();
                    } else {
                        RugbyTimerTiming.triggerPenaltyWarningVibe();
                    }
                }
            }
            
            if (!timersPaused) {
                var homeYellowUpdate = RugbyTimerCards.updateYellowTimers(model, model.yellowHomeTimes, now);
                model.yellowHomeTimes = homeYellowUpdate["timers"];
                var awayYellowUpdate = RugbyTimerCards.updateYellowTimers(model, model.yellowAwayTimes, now);
                model.yellowAwayTimes = awayYellowUpdate["timers"];
                if (homeYellowUpdate["expired"] == true || awayYellowUpdate["expired"] == true) {
                    RugbyTimerTiming.triggerYellowTimerExpiredVibe();
                }

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
     * Normalizes a countdown-style timer for display so it does not drop a second early
     * on one screen while another renderer still shows the higher value.
     * @param seconds The raw countdown value
     * @return A clamped, display-ready number of seconds
     */
    static function getDisplayCountdownSeconds(seconds) {
        if (seconds == null || seconds < 0) {
            return 0;
        }
        return seconds + 0.999;
    }

    /**
     * Normalized haptics helper so vibration sequences stay consistent across events.
     */
    static function vibrateSequence(vibeProfiles) {
        if (Attention has :vibrate) {
            Attention.vibrate(vibeProfiles);
        }
    }

    static function triggerMatchStartVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(35, 100),
            new Attention.VibeProfile(55, 160)
        ]);
    }

    static function triggerPauseVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(30, 120)
        ]);
    }

    static function triggerResumeVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(45, 140)
        ]);
    }

    static function triggerLockToggleVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(25, 80)
        ]);
    }

    static function triggerHalfEndingSoonVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(50, 500)
        ]);
    }

    static function triggerHalfTimeVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(65, 160),
            new Attention.VibeProfile(65, 220)
        ]);
    }

    static function triggerFullTimeVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(70, 180),
            new Attention.VibeProfile(40, 120),
            new Attention.VibeProfile(70, 260)
        ]);
    }

    static function triggerConversionStartVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(35, 120)
        ]);
    }

    static function triggerPenaltyStartVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(25, 90),
            new Attention.VibeProfile(25, 90)
        ]);
    }

    static function triggerConversionWarningVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(45, 120),
            new Attention.VibeProfile(45, 120)
        ]);
    }

    static function triggerPenaltyWarningVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(35, 100),
            new Attention.VibeProfile(35, 100),
            new Attention.VibeProfile(35, 100)
        ]);
    }

    static function triggerConversionExpiredVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(65, 180),
            new Attention.VibeProfile(65, 180)
        ]);
    }

    static function triggerPenaltyExpiredVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(55, 150),
            new Attention.VibeProfile(55, 150),
            new Attention.VibeProfile(55, 150)
        ]);
    }

    /**
     * Triggers a vibration for the yellow card timer warning.
     */
    static function triggerYellowTimerWarningVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(60, 300)
        ]);
    }

    static function triggerYellowTimerExpiredVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(55, 130),
            new Attention.VibeProfile(55, 130)
        ]);
    }
}
