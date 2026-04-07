using Toybox.Lang;

/**
 * Shared state-integrity guardrails for startup, rendering, and persistence.
 *
 * Purpose: keep core timing/state invariants centralized so new features cannot
 * accidentally strand the app in invalid idle/halftime/live combinations.
 */
class RugbyMatchIntegritySupport {
    static function isKnownGameState(state) {
        return state instanceof Lang.Number
            && state >= STATE_IDLE
            && state <= STATE_ENDED;
    }

    static function getSafeHalfDuration(model) {
        var configuredHalfDuration = model.halfDuration;
        if (!RugbyTimeMath.isNumeric(configuredHalfDuration) || configuredHalfDuration <= 0) {
            configuredHalfDuration = RugbyMatchProfiles.getDefaultHalfDuration(model != null && model.is7s == true);
        }
        return RugbyTimeMath.normalizeSeconds(configuredHalfDuration);
    }

    static function getClampedCountdownRemaining(model, safeHalfDuration) {
        var remaining = model.countdownRemaining;
        if (!RugbyTimeMath.isNumeric(remaining)) {
            remaining = RugbyTimeMath.getCountdownRemaining(safeHalfDuration, model.gameTime);
        }
        remaining = RugbyTimeMath.normalizeSeconds(remaining);
        if (remaining < 0) { return 0; }
        if (remaining > safeHalfDuration) { return safeHalfDuration; }
        return remaining;
    }

    static function reconcileModelState(model) {
        if (model == null) {
            return;
        }

        if (!RugbyMatchIntegritySupport.isKnownGameState(model.gameState)) {
            model.gameState = STATE_IDLE;
        }

        var safeHalfDuration = RugbyMatchIntegritySupport.getSafeHalfDuration(model);
        model.halfDuration = safeHalfDuration;
        model.countdownTimer = safeHalfDuration;

        if (!RugbyTimeMath.isNumeric(model.halfNumber) || model.halfNumber < 1) {
            model.halfNumber = 1;
        } else if (model.halfNumber > 2) {
            model.halfNumber = 2;
        }

        if (!RugbyTimeMath.isNumeric(model.gameTime) || model.gameTime < 0) {
            model.gameTime = 0;
        }
        if (!RugbyTimeMath.isNumeric(model.elapsedTime) || model.elapsedTime < 0) {
            model.elapsedTime = 0;
        }
        if (!RugbyTimeMath.isNumeric(model.suspensionTime) || model.suspensionTime < 0) {
            model.suspensionTime = 0;
        }
        if (!RugbyTimeMath.isNumeric(model.countdownSeconds) || model.countdownSeconds < 0) {
            model.countdownSeconds = 0;
        }

        if (model.gameState == STATE_IDLE) {
            model.gameTime = 0;
            model.elapsedTime = 0;
            model.suspensionTime = 0;
            model.countdownSeconds = 0;
            model.countdownRemaining = safeHalfDuration;
            model.pausedState = null;
            model.lastPauseReminderTime = null;
            model.conversionTeam = null;
            model.conversionStartTime = null;
            model.penaltyStartTime = null;
            model.kickoffStartTime = null;
            model.specialAlertTriggered = false;
            model.thirtySecondAlerted = false;
            return;
        }

        if (model.gameState == STATE_HALFTIME) {
            if (model.countdownSeconds <= 0) {
                model.countdownSeconds = 0;
                model.gameTime = 0;
            }
            model.countdownRemaining = safeHalfDuration;
            model.pausedState = null;
            model.conversionTeam = null;
            model.conversionStartTime = null;
            model.penaltyStartTime = null;
            return;
        }

        model.countdownRemaining = RugbyMatchIntegritySupport.getClampedCountdownRemaining(model, safeHalfDuration);
    }
}
