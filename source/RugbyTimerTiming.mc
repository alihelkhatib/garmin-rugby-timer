using Toybox.Attention;
using Toybox.System;
using Toybox.WatchUi;

class RugbyTimerTiming {
    static function updateGame(view) as Void {
        try {
            var now = System.getTimer();
            if (view.gameStartTime != null) {
                view.elapsedTime = (now - view.gameStartTime) / 1000;
            }

            var delta = 0;
            if (view.lastUpdate != null) {
                delta = (now - view.lastUpdate) / 1000.0;
                if (delta < 0) {
                    delta = 0;
                }
            }
            if (delta > 0 && view.gameState != STATE_IDLE && view.gameState != STATE_ENDED) {
                view.gameTime = view.gameTime + delta;
            }

            if (view.gameState == STATE_PLAYING || view.gameState == STATE_CONVERSION || view.gameState == STATE_PENALTY || view.gameState == STATE_KICKOFF) {
                view.countdownRemaining = view.countdownRemaining - delta;
                if (view.countdownRemaining < 0) { view.countdownRemaining = 0; }
                if (view.countdownRemaining <= 30 && view.countdownRemaining > 0 && !view.thirtySecondAlerted) {
                    view.thirtySecondAlerted = true;
                    RugbyTimerTiming.triggerThirtySecondVibe();
                }

                if (view.gameState == STATE_CONVERSION || view.gameState == STATE_PENALTY || view.gameState == STATE_KICKOFF) {
                    view.countdownSeconds = view.countdownSeconds - delta;
                    if (view.countdownSeconds <= 0) {
                        view.countdownSeconds = 0;
                        if (view.gameState == STATE_CONVERSION) {
                            view.startKickoffCountdown();
                        } else if (view.gameState == STATE_PENALTY) {
                            view.resumePlay();
                        } else {
                            view.resumePlay();
                        }
                    }
                    if (view.countdownSeconds <= 15 && view.countdownSeconds > 0 && !view.specialAlertTriggered) {
                        view.specialAlertTriggered = true;
                        RugbyTimerTiming.triggerSpecialTimerVibe();
                    }
                }

                view.yellowHomeTimes = RugbyTimerCards.updateYellowTimers(view, view.yellowHomeTimes, delta);
                view.yellowAwayTimes = RugbyTimerCards.updateYellowTimers(view, view.yellowAwayTimes, delta);
                if (!view.redHomePermanent && view.redHome > 0) { view.redHome = view.redHome - delta; if (view.redHome < 0) { view.redHome = 0; } }
                if (!view.redAwayPermanent && view.redAway > 0) { view.redAway = view.redAway - delta; if (view.redAway < 0) { view.redAway = 0; } }

                if (view.countdownRemaining <= 0) {
                    view.countdownRemaining = 0;
                    if (view.halfNumber == 1) {
                        view.enterHalfTime();
                    } else {
                        view.endGame();
                    }
                }
            }

            view.lastUpdate = now;
            if (view.lastPersistTime == 0 || now - view.lastPersistTime > view.STATE_SAVE_INTERVAL_MS) {
                RugbyTimerPersistence.saveState(view);
                view.lastPersistTime = now;
            }

            WatchUi.requestUpdate();
        } catch (ex) {
            // Silently handle errors to prevent crash
        }
    }

    static function formatTime(seconds) {
        if (seconds < 0) {
            seconds = 0;
        }
        var mins = (seconds.toLong() / 60);
        var secs = (seconds.toLong() % 60);
        return mins.format("%02d") + ":" + secs.format("%02d");
    }

    static function triggerThirtySecondVibe() {
        if (Attention has :vibrate) {
            var vibeProfiles = [
                new Attention.VibeProfile(50, 500)
            ];
            Attention.vibrate(vibeProfiles);
        }
    }

    static function triggerSpecialTimerVibe() {
        if (Attention has :vibrate) {
            var vibeProfiles = [
                new Attention.VibeProfile(40, 400)
            ];
            Attention.vibrate(vibeProfiles);
        }
    }
}
