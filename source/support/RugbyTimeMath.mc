using Toybox.Lang;

/**
 * Shared helpers for match-clock math and display formatting.
 *
 * Purpose: keep numeric guards, delta calculations, snapshot math, and
 * countdown formatting consistent across the live update loop, pause/sync
 * transitions, and persistence snapshot code.
 */
class RugbyTimeMath {
    static function isNumeric(value) {
        return value instanceof Lang.Number || value instanceof Lang.Float;
    }

    static function normalizeSeconds(value) {
        if (!RugbyTimeMath.isNumeric(value)) {
            return 0;
        }
        return value;
    }

    static function getDeltaSeconds(lastUpdate, now) {
        if (!RugbyTimeMath.isNumeric(lastUpdate) || !RugbyTimeMath.isNumeric(now)) {
            return 0;
        }
        var deltaSeconds = (now - lastUpdate) / 1000.0f;
        if (deltaSeconds < 0) {
            return 0;
        }
        return deltaSeconds;
    }

    static function getCountdownRemaining(countdownTimer, gameTime) {
        var remaining = RugbyTimeMath.normalizeSeconds(countdownTimer) - RugbyTimeMath.normalizeSeconds(gameTime);
        if (remaining < 0) {
            return 0;
        }
        return remaining;
    }

    static function snapshotForwardClock(value, lastUpdate, now, isRunning) {
        var snapshot = RugbyTimeMath.normalizeSeconds(value);
        if (isRunning) {
            snapshot = snapshot + RugbyTimeMath.getDeltaSeconds(lastUpdate, now);
        }
        return snapshot;
    }

    static function snapshotReverseClock(value, lastUpdate, now, isRunning) {
        var snapshot = RugbyTimeMath.normalizeSeconds(value);
        if (isRunning) {
            snapshot = snapshot - RugbyTimeMath.getDeltaSeconds(lastUpdate, now);
        }
        if (snapshot < 0) {
            return 0;
        }
        return snapshot;
    }

    static function applyCoreClockDelta(model, deltaSeconds, elapsedClockRunning, mainClockRunning, suspensionClockRunning) {
        model.gameTime = RugbyTimeMath.normalizeSeconds(model.gameTime);
        model.suspensionTime = RugbyTimeMath.normalizeSeconds(model.suspensionTime);
        model.elapsedTime = RugbyTimeMath.normalizeSeconds(model.elapsedTime);

        if (elapsedClockRunning) {
            model.elapsedTime = model.elapsedTime + deltaSeconds;
        }
        if (mainClockRunning) {
            model.gameTime = model.gameTime + deltaSeconds;
            model.countdownRemaining = RugbyTimeMath.getCountdownRemaining(model.countdownTimer, model.gameTime);
        }
        if (suspensionClockRunning) {
            model.suspensionTime = model.suspensionTime + deltaSeconds;
        }
    }

    static function formatShortTime(seconds) {
        if (!RugbyTimeMath.isNumeric(seconds) || seconds <= 0) {
            return "--";
        }
        var mins = (seconds.toLong() / 60);
        var secs = (seconds.toLong() % 60);
        return mins.toString() + ":" + secs.format("%02d");
    }
}
