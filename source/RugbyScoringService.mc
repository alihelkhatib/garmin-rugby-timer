/**
 * Scoring and undo/history service for match events.
 *
 * Purpose: keep score mutations, conversion transitions, and recent-event
 * bookkeeping in one place instead of spreading them across UI and model code.
 */
class RugbyScoringService {
    static function addEvent(model, eventType, isHome) {
        var entry = ScoreEvent.create(eventType, isHome);
        if (entry != null) {
            model.lastEvents.add(entry.toDict());
        }
    }

    static function trimEvents(model) {
        if (model.lastEvents.size() > 20) {
            model.lastEvents.remove(0);
        }
    }

    static function recordTry(model, isHome) {
        if (isHome) {
            model.homeScore += 5;
            model.homeTries += 1;
        } else {
            model.awayScore += 5;
            model.awayTries += 1;
        }
        RugbyScoringService.addEvent(model, :try, isHome);
        RugbyScoringService.trimEvents(model);
        if (RugbyMatchStateSupport.shouldStartConversionAfterTry(model.gameState, model.useConversionTimer)) {
            model.conversionTeam = isHome;
            RugbyClockService.startConversionCountdown(model);
        }
        RugbyTimerEventLog.appendEntry(model, RugbyTeamIdentitySupport.buildEventDescription(model, isHome, "Try"));
        RugbySnapshotService.persistState(model);
    }

    static function recordConversion(model, isHome) {
        if (isHome) {
            model.homeScore += 2;
        } else {
            model.awayScore += 2;
        }
        RugbyScoringService.addEvent(model, :conversion, isHome);
        RugbyScoringService.trimEvents(model);
        model.conversionTeam = null;
        RugbyTimerEventLog.appendEntry(model, RugbyTeamIdentitySupport.buildEventDescription(model, isHome, "Conversion (made)"));
        if (model.gameState == STATE_CONVERSION) {
            RugbyClockService.resumePlay(model);
        } else {
            RugbySnapshotService.persistState(model);
        }
    }

    static function recordPenalty(model, isHome) {
        if (isHome) {
            model.homeScore += 3;
            model.homePenalties += 1;
        } else {
            model.awayScore += 3;
            model.awayPenalties += 1;
        }
        RugbyScoringService.addEvent(model, :penalty, isHome);
        RugbyScoringService.trimEvents(model);
        if (RugbyMatchStateSupport.shouldStartPenaltyAfterKick(model.gameState, model.usePenaltyTimer)) {
            RugbyClockService.startPenaltyCountdown(model);
        }
        RugbyTimerEventLog.appendEntry(model, RugbyTeamIdentitySupport.buildEventDescription(model, isHome, "Penalty Goal"));
        RugbySnapshotService.persistState(model);
    }

    static function recordDropGoal(model, isHome) {
        if (isHome) {
            model.homeScore += 3;
        } else {
            model.awayScore += 3;
        }
        RugbyScoringService.addEvent(model, :drop, isHome);
        RugbyScoringService.trimEvents(model);
        RugbyTimerEventLog.appendEntry(model, RugbyTeamIdentitySupport.buildEventDescription(model, isHome, "Drop Goal"));
        RugbySnapshotService.persistState(model);
    }

    static function recordPenaltyTry(model, isHome) {
        if (isHome) {
            model.homeScore += 7;
        } else {
            model.awayScore += 7;
        }
        RugbyScoringService.addEvent(model, :penalty_try, isHome);
        RugbyScoringService.trimEvents(model);
        RugbyTimerEventLog.appendEntry(model, RugbyTeamIdentitySupport.buildEventDescription(model, isHome, "Penalty Try"));
        RugbySnapshotService.persistState(model);
    }

    static function undoLastEvent(model) {
        if (model.lastEvents.size() == 0) {
            return false;
        }
        var eventEntry = ScoreEvent.fromDict(model.lastEvents.remove(model.lastEvents.size() - 1));
        if (eventEntry == null) {
            RugbySnapshotService.persistState(model);
            return true;
        }
        var isHome = eventEntry.isHome;
        if (eventEntry.isType(:try)) {
            if (isHome) {
                model.homeScore = model.homeScore - 5;
                if (model.homeScore < 0) { model.homeScore = 0; }
                if (model.homeTries > 0) { model.homeTries -= 1; }
            } else {
                model.awayScore = model.awayScore - 5;
                if (model.awayScore < 0) { model.awayScore = 0; }
                if (model.awayTries > 0) { model.awayTries -= 1; }
            }
        } else if (eventEntry.isType(:conversion)) {
            if (isHome) {
                model.homeScore = model.homeScore - 2;
                if (model.homeScore < 0) { model.homeScore = 0; }
            } else {
                model.awayScore = model.awayScore - 2;
                if (model.awayScore < 0) { model.awayScore = 0; }
            }
        } else if (eventEntry.isType(:penalty_try)) {
            if (isHome) {
                model.homeScore = model.homeScore - 7;
                if (model.homeScore < 0) { model.homeScore = 0; }
            } else {
                model.awayScore = model.awayScore - 7;
                if (model.awayScore < 0) { model.awayScore = 0; }
            }
        } else if (eventEntry.isType(:penalty) || eventEntry.isType(:drop)) {
            if (isHome) {
                model.homeScore = model.homeScore - 3;
                if (model.homeScore < 0) { model.homeScore = 0; }
            } else {
                model.awayScore = model.awayScore - 3;
                if (model.awayScore < 0) { model.awayScore = 0; }
            }
        }
        RugbySnapshotService.persistState(model);
        return true;
    }
}
