using Toybox.Graphics;
using Toybox.Lang;
using Rez.Drawables;

/**
 * Live-screen presentation helper.
 *
 * Purpose: keep text, color, icon, and sanction-selection rules in one place
 * while the view binds those results into XML-owned drawables.
 */
class RugbyTimerRenderer {
    static function shouldShowIcons(family) {
        return family != "compact_round";
    }

    static function shouldShowTries(family) {
        return family != "compact_round";
    }

    static function getElapsedTimerText(model) {
        return RugbyTimerTiming.formatTime(model.elapsedTime);
    }

    static function getCountdownText(model) {
        var displaySeconds = RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownRemaining);
        return RugbyTimerTiming.formatTime(displaySeconds);
    }

    static function getHalfText(model) {
        return "Half " + model.halfNumber.toString();
    }

    static function getHomeTriesText(model) {
        return model.homeTries.toString() + "T";
    }

    static function getAwayTriesText(model) {
        return model.awayTries.toString() + "T";
    }


    static function getHintMode(gameState, isLocked, showIdleHints) {
        if (isLocked) {
            return "locked";
        }
        if (gameState == STATE_IDLE && showIdleHints) {
            return "idle";
        }
        return "hidden";
    }

    static function getMainStateColor(model) {
        if (model.gameState == STATE_PAUSED || model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY) {
            return Graphics.COLOR_RED;
        }
        return Graphics.COLOR_WHITE;
    }

    static function getMainStateLine1(model) {
        if (model.gameState == STATE_PAUSED) {
            return "PAUSED";
        } else if (model.gameState == STATE_CONVERSION) {
            return "CONVERSION";
        } else if (model.gameState == STATE_PENALTY) {
            return "PENALTY KICK";
        } else if (model.gameState == STATE_HALFTIME) {
            return "HALF TIME";
        } else if (model.gameState == STATE_ENDED) {
            return "GAME ENDED";
        }
        return "";
    }

    static function getMainStateLine2(model) {
        if (model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY) {
            var remaining = RugbyTimerTiming.getDisplayCountdownSeconds(model.countdownSeconds);
            return remaining.toLong().toString() + "s";
        }
        return "";
    }

    static function canonicalCardLabel(label, prefix, fallbackId) {
        if (label instanceof Lang.String) {
            var normalized = label;
            while (normalized.length() > 0 && normalized.substring(0, 1) == " ") {
                normalized = normalized.substring(1, normalized.length());
            }
            while (normalized.length() > 0 && normalized.substring(normalized.length() - 1, normalized.length()) == " ") {
                normalized = normalized.substring(0, normalized.length() - 1);
            }
            if (normalized.length() > 0) {
                return normalized;
            }
        }
        return prefix + fallbackId.toString();
    }

    static function getUrgentCardEntry(entries, timerNow) {
        if (entries == null) {
            return null;
        }
        var bestEntry = null;
        var bestRemaining = null;
        for (var i = 0; i < entries.size(); i = i + 1) {
            var entry = CardEntry.fromDict(entries[i]);
            if (entry == null) {
                continue;
            }
            var remaining = entry.remaining;
            if (!RugbyTimerCards.isNumeric(remaining)) {
                remaining = RugbyTimerCards.getEntryRemaining(entry, timerNow);
            }
            if (!RugbyTimerCards.isNumeric(remaining) || remaining <= 0) {
                continue;
            }
            if (bestRemaining == null || remaining < bestRemaining) {
                bestRemaining = remaining;
                bestEntry = entry;
                bestEntry.remaining = remaining;
            }
        }
        return bestEntry;
    }

    static function getTeamCardPresentation(model, yellowEntries, redEntries, permanentRed, redCounter) {
        if (model == null) {
            return RugbyCardSlotPresentation.create("", "", Graphics.COLOR_WHITE, false);
        }
        var timerNow = model.suspensionTime;
        if (!(timerNow instanceof Lang.Number) && !(timerNow instanceof Lang.Float)) {
            timerNow = 0;
        }
        var urgentYellow = RugbyTimerRenderer.getUrgentCardEntry(yellowEntries, timerNow);
        var urgentRed = null;
        if (!permanentRed) {
            urgentRed = RugbyTimerRenderer.getUrgentCardEntry(redEntries, timerNow);
        }

        var bestEntry = urgentYellow;
        var bestColor = Graphics.COLOR_YELLOW;
        if (urgentRed != null && (bestEntry == null || urgentRed.remaining < bestEntry.remaining)) {
            bestEntry = urgentRed;
            bestColor = Graphics.COLOR_RED;
        }
        if (bestEntry != null) {
            var prefix = bestColor == Graphics.COLOR_RED ? "R" : "Y";
            var fallbackId = 1;
            if (bestEntry.cardId instanceof Lang.Number || bestEntry.cardId instanceof Lang.Float) {
                fallbackId = bestEntry.cardId;
            }
            return RugbyCardSlotPresentation.create(
                RugbyTimerRenderer.canonicalCardLabel(bestEntry.label, prefix, fallbackId),
                model.formatShortTime(RugbyTimerTiming.getDisplayCountdownSeconds(bestEntry.remaining)),
                bestColor,
                true
            );
        }
        if (permanentRed) {
            var label = redCounter > 0 ? "R" + redCounter.toString() : "R";
            return RugbyCardSlotPresentation.create(label, "PERM", Graphics.COLOR_RED, true);
        }
        return RugbyCardSlotPresentation.create("", "", Graphics.COLOR_WHITE, false);
    }
}
