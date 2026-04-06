/**
 * Pure match-state transition rules shared by clock, scoring, delegate, and
 * persistence code.
 *
 * Purpose: keep state classification and next-action decisions in one place so
 * behavior-sensitive transition checks do not drift across modules.
 */
class RugbyMatchStateSupport {
    static function isMainClockRunning(state) {
        return state == STATE_PLAYING || state == STATE_CONVERSION || state == STATE_PENALTY || state == STATE_KICKOFF;
    }

    static function isSuspensionClockRunning(state) {
        return state == STATE_PLAYING || state == STATE_CONVERSION || state == STATE_PENALTY || state == STATE_HALFTIME || state == STATE_KICKOFF;
    }

    static function shouldRestoreAsPaused(state) {
        return RugbyMatchStateSupport.isMainClockRunning(state);
    }

    static function getRestoredPausedState(savedGameState, savedPausedState) {
        if (savedPausedState == STATE_KICKOFF) {
            savedPausedState = STATE_PLAYING;
        }
        if (savedPausedState != null) {
            return savedPausedState;
        }
        if (savedGameState == STATE_KICKOFF) {
            return STATE_PLAYING;
        }
        if (savedGameState == STATE_PLAYING || savedGameState == STATE_CONVERSION || savedGameState == STATE_PENALTY) {
            return savedGameState;
        }
        return STATE_PLAYING;
    }

    static function getResumeState(pausedState) {
        if (pausedState != null) {
            return pausedState;
        }
        return STATE_PLAYING;
    }

    static function shouldStartRecordingForState(state) {
        return state == STATE_PLAYING || state == STATE_CONVERSION || state == STATE_PENALTY;
    }

    static function shouldResumeActiveClockFromPause(state) {
        return state == STATE_PLAYING || state == STATE_CONVERSION || state == STATE_PENALTY;
    }

    static function shouldStartConversionAfterTry(state, useConversionTimer) {
        return state == STATE_PLAYING && useConversionTimer == true;
    }

    static function shouldStartPenaltyAfterKick(state, usePenaltyTimer) {
        return state == STATE_PLAYING && usePenaltyTimer == true;
    }

    static function getSelectAction(state) {
        if (state == STATE_IDLE) {
            return :start_game;
        }
        if (state == STATE_PLAYING || state == STATE_CONVERSION || state == STATE_PENALTY) {
            return :pause_clock;
        }
        if (state == STATE_PAUSED) {
            return :resume_clock;
        }
        if (state == STATE_HALFTIME) {
            return :start_half2;
        }
        return null;
    }
}
