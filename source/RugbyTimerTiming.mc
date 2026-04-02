using Toybox.Attention;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Lang;

/**
 * A helper class for handling game timing.
 */
class RugbyTimerTiming {
        static function isNumeric(value) {
            return value instanceof Lang.Number || value instanceof Lang.Float;
        }

    static function isClockRunning(state) {
        return state == STATE_PLAYING || state == STATE_CONVERSION || state == STATE_PENALTY || state == STATE_KICKOFF;
    }

    static function isSuspensionClockRunning(state) {
        return state == STATE_PLAYING || state == STATE_CONVERSION || state == STATE_PENALTY || state == STATE_HALFTIME || state == STATE_KICKOFF;
    }

    const HALF_WARNING_SECONDS = 30;
    const SPECIAL_WARNING_SECONDS = 10;
    /**
     * This method is called periodically to update the game state.
     * @param model The game model
     */
    static function updateGame(model) {
        try {
            var now = System.getTimer();
            if (model.lastUpdate == null) {
                model.lastUpdate = now;
                return;
            }

            var deltaSeconds = (now - model.lastUpdate) / 1000.0f;
            if (deltaSeconds < 0) { deltaSeconds = 0; }

            if (!RugbyTimerTiming.isNumeric(model.gameTime)) {
                model.gameTime = 0;
            }
            if (!RugbyTimerTiming.isNumeric(model.suspensionTime)) {
                model.suspensionTime = 0;
            }
            if (!RugbyTimerTiming.isNumeric(model.elapsedTime)) {
                model.elapsedTime = 0;
            }

            var mainClockRunning = RugbyTimerTiming.isClockRunning(model.gameState);
            var elapsedClockRunning = model.gameState != STATE_IDLE && model.gameState != STATE_ENDED;
            if (elapsedClockRunning) {
                model.elapsedTime = model.elapsedTime + deltaSeconds;
            }
            if (mainClockRunning) {
                model.gameTime = model.gameTime + deltaSeconds;
            }
            if (RugbyTimerTiming.isSuspensionClockRunning(model.gameState)) {
                model.suspensionTime = model.suspensionTime + deltaSeconds;
            }

            // Keep the half countdown locked to the canonical match clock so they cannot drift.
            if (mainClockRunning) {
                model.countdownRemaining = model.countdownTimer - model.gameTime;
                if (model.countdownRemaining < 0) { model.countdownRemaining = 0; }
                if (model.countdownRemaining <= 30 && model.countdownRemaining > 0 && !model.thirtySecondAlerted) {
                    model.thirtySecondAlerted = true;
                    RugbyTimerTiming.triggerHalfEndingSoonVibe();
                }
            }

            // Special timers tick only when active and not paused
            if (mainClockRunning && (model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY)) {
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
            
            var suspensionClockRunning = RugbyTimerTiming.isSuspensionClockRunning(model.gameState);
            if (suspensionClockRunning) {
                var homeYellowUpdate = RugbyTimerCards.updateYellowTimers(model, model.yellowHomeTimes, model.suspensionTime);
                model.yellowHomeTimes = homeYellowUpdate["timers"];
                var awayYellowUpdate = RugbyTimerCards.updateYellowTimers(model, model.yellowAwayTimes, model.suspensionTime);
                model.yellowAwayTimes = awayYellowUpdate["timers"];
                if (homeYellowUpdate["expired"] == true || awayYellowUpdate["expired"] == true) {
                    RugbyTimerTiming.triggerYellowTimerExpiredVibe();
                }

                // Red card timers (same mechanism as yellow cards)
                var homeRedUpdate = RugbyTimerCards.updateYellowTimers(model, model.redHomeTimes, model.suspensionTime);
                model.redHomeTimes = homeRedUpdate["timers"];
                var awayRedUpdate = RugbyTimerCards.updateYellowTimers(model, model.redAwayTimes, model.suspensionTime);
                model.redAwayTimes = awayRedUpdate["timers"];
            }

            if (model.gameState == STATE_PAUSED) {
                if (!(model.lastPauseReminderTime instanceof Lang.Number) && !(model.lastPauseReminderTime instanceof Lang.Float)) {
                    model.lastPauseReminderTime = now;
                // Keep the reminder cadence fixed and simple while paused.
                } else if (((now - model.lastPauseReminderTime) / 1000.0f) >= 5) {
                    model.lastPauseReminderTime = now;
                    RugbyTimerTiming.triggerPauseReminderVibe();
                }
            }

            if (mainClockRunning && model.countdownRemaining <= 0) {
                model.countdownRemaining = 0;
                if (model.halfNumber == 1) {
                    model.enterHalfTime();
                } else {
                    model.endGame();
                }
            }

            model.lastUpdate = now;
            if (model.lastPersistTime == 0 || now - model.lastPersistTime > model.STATE_SAVE_INTERVAL_MS) {
                model.persistState();
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

    static function triggerPauseReminderVibe() {
        RugbyTimerTiming.vibrateSequence([
            new Attention.VibeProfile(35, 150)
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
