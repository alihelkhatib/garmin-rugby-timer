/**
 * Discipline-rule service for yellow and red card events.
 *
 * Purpose: centralize sanction timing, numbering, totals, and event-log
 * side effects so discipline behavior does not stay embedded in the model.
 */
using Rez.Strings;

class RugbyDisciplineService {
    static function formatCardLabel(prefix, cardId) {
        return prefix + cardId.toString();
    }

    static function recordYellowCard(model, isHome) {
        if (model.gameState != STATE_IDLE && model.gameState != STATE_HALFTIME && model.gameState != STATE_PAUSED && model.gameState != STATE_ENDED) {
            RugbyClockService.pauseClock(model);
        }
        var duration = model.getYellowCardDuration();
        var cardId = RugbyTimerCards.allocateYellowCardId(model, isHome);
        var label = formatCardLabel(RugbyStrings.getCardPrefix(false), cardId);
        var entry = RugbyTimerCards.createYellowCardEntryFromStartTime(model.suspensionTime, duration, label, cardId);
        if (isHome) {
            model.yellowHomeTimes.add(entry);
            model.yellowHomeTotal = model.yellowHomeTotal + 1;
        } else {
            model.yellowAwayTimes.add(entry);
            model.yellowAwayTotal = model.yellowAwayTotal + 1;
        }
        RugbyTimerEventLog.appendEntry(model, RugbyStrings.getEventTeamLabel(isHome) + " " + RugbyStrings.load(Rez.Strings.Event_YellowCard) + " (" + label + ")");
        model.schedulePersistState();
    }

    static function recordRedCard(model, isHome) {
        if (model.gameState != STATE_IDLE && model.gameState != STATE_HALFTIME && model.gameState != STATE_PAUSED && model.gameState != STATE_ENDED) {
            RugbyClockService.pauseClock(model);
        }
        var redDuration = model.getRedCardDuration();
        var cardId = RugbyTimerCards.allocateRedCardId(model, isHome);
        var label = formatCardLabel(RugbyStrings.getCardPrefix(true), cardId);
        if (model.usesSevensCardRules()) {
            if (isHome) {
                model.redHomePermanent = true;
            } else {
                model.redAwayPermanent = true;
            }
        } else {
            var entry = RugbyTimerCards.createYellowCardEntryFromStartTime(model.suspensionTime, redDuration, label, cardId);
            if (isHome) {
                model.redHomeTimes.add(entry);
                model.redHomePermanent = false;
            } else {
                model.redAwayTimes.add(entry);
                model.redAwayPermanent = false;
            }
        }
        if (isHome) {
            model.redHomeTotal = model.redHomeTotal + 1;
        } else {
            model.redAwayTotal = model.redAwayTotal + 1;
        }
        RugbyTimerEventLog.appendEntry(
            model,
            RugbyStrings.getEventTeamLabel(isHome)
                + " "
                + RugbyStrings.load(Rez.Strings.Event_RedCard)
                + " ("
                + label
                + ")"
                + (model.usesSevensCardRules() ? RugbyStrings.load(Rez.Strings.Event_PermanentSuffix) : "")
        );
        model.schedulePersistState();
    }
}
