using Toybox.Lang;
using Toybox.System;

/**
 * A helper class for managing yellow and red card timers.
 */
class RugbyTimerCards {
    static function isNumeric(value) {
        return value instanceof Lang.Number || value instanceof Lang.Float;
    }

    static function clampRemaining(remaining, duration) {
        if (!RugbyTimerCards.isNumeric(remaining)) {
            return 0;
        }
        if (remaining < 0) { remaining = 0; }
        if (RugbyTimerCards.isNumeric(duration) && remaining > duration) {
            remaining = duration;
        }
        return remaining;
    }

    static function getRedRemaining(startTime, now) {
        if (!(startTime instanceof Lang.Number)) {
            return null;
        }
        var remaining = 1200 - ((now - startTime) / 1000.0f);
        if (remaining <= 0) {
            return null;
        }
        if (remaining > 1200) { remaining = 1200; }
        return remaining;
    }

    static function restoreRedStartTime(remaining, now) {
        if (!(remaining instanceof Lang.Number) || remaining <= 0) {
            return null;
        }
        if (remaining > 1200) { remaining = 1200; }
        return now - ((1200 - remaining) * 1000.0f);
    }

    static function getEntryRemaining(entry, clockValue) {
        if (entry == null) { return 0; }
        var ce = entry;
        if (!(ce instanceof CardEntry)) {
            ce = CardEntry.fromDict(entry);
        }
        if (ce == null) { return 0; }

        var duration = ce.duration;
        var startTime = ce.startTime;
        // Timer is live: startTime and clockValue are both expressed in the same
        // derived sanction-clock seconds, so no wall-clock conversion is needed.
        if (RugbyTimerCards.isNumeric(startTime) && RugbyTimerCards.isNumeric(duration) && RugbyTimerCards.isNumeric(clockValue)) {
            var elapsedSecs = clockValue - startTime;
            if (elapsedSecs < 0) { elapsedSecs = 0; }
            var remaining = duration - elapsedSecs;
            if (remaining < 0) { remaining = 0; }
            if (remaining > duration) { remaining = duration; }
            return remaining;
        }
        // Timer is paused/frozen: use stored remaining.
        var stored = ce.remaining;
        if (RugbyTimerCards.isNumeric(stored) && stored > 0) {
            return stored;
        }
        // Fallback: return full duration so a fresh card never shows '--'.
        if (RugbyTimerCards.isNumeric(duration)) {
            return duration;
        }
        return 0;
    }

    static function getLiveEntryRemaining(entry, clockValue) {
        return RugbyTimerCards.getEntryRemaining(entry, clockValue);
    }

    /**
     * Creates a sanction entry from the current sanction-clock position.
     * @param startTime The `suspensionTime` clock position when the card started
     * @param duration The total duration of the card
     * @param label The label for the card (e.g., "Y1")
     * @param cardId The ID of the card
     * @param vibeTriggered A boolean indicating if the vibration has been triggered for this card
     * @return A dictionary representing the yellow card entry
     */
    static function createYellowCardEntryFromStartTime(startTime, duration, label, cardId) {
        var e = CardEntry.createFromStartTime(startTime, duration, label, cardId);
        return e.toDict();
    }

    /**
     * Updates live yellow/red card timers from the current absolute timestamp.
     * @param model The game model
     * @param list The list of yellow/red card timers
     * @param now The current System.getTimer() value
     * @return A dictionary containing the updated timers plus an expiry flag
     */
    static function updateYellowTimers(model, list, now) {
        var newList = [];
        var expiredAny = false;
        if (!RugbyTimerCards.isNumeric(now) || now < 0) {
            now = System.getTimer();
        }
        for (var i = 0; i < list.size(); i = i + 1) {
            var raw = list[i] as Lang.Dictionary;
            if (raw == null) { continue; }
            var ce = CardEntry.fromDict(raw);
            if (ce == null) { continue; }

            var duration = ce.duration;
            var startTime = ce.startTime;
            var storedRemaining = ce.remaining;

            if (!RugbyTimerCards.isNumeric(duration) && RugbyTimerCards.isNumeric(storedRemaining)) {
                duration = storedRemaining;
            }

            if (!RugbyTimerCards.isNumeric(duration)) { continue; }

            var remaining = RugbyTimerCards.getLiveEntryRemaining(ce, now);
            remaining = RugbyTimerCards.clampRemaining(remaining, duration);

            // Safety: never expire a card within the first 2 seconds of creation.
            if (remaining <= 0) {
                if (startTime instanceof Lang.Number) {
                    var ageMs = now - startTime;
                    if (ageMs < 2000) {
                        remaining = duration;
                    }
                } else if (RugbyTimerCards.isNumeric(storedRemaining) && storedRemaining > 0) {
                    remaining = storedRemaining;
                }
            }

            if (remaining <= 0) {
                expiredAny = true;
                continue;
            }

            ce.vibeTriggered = (ce.vibeTriggered == true);
            if (!ce.vibeTriggered && remaining <= 10) {
                ce.vibeTriggered = true;
                RugbyTimerTiming.triggerYellowTimerWarningVibe();
            }
            ce.remaining = remaining;
            newList.add(ce.toDict());
        }
        return {
            "timers" => newList,
            "expired" => expiredAny
        };
    }

    static function pauseYellowTimers(list, now) {
        var pausedList = [];
        if (list == null) {
            return pausedList;
        }
        for (var i = 0; i < list.size(); i = i + 1) {
            var raw = list[i] as Lang.Dictionary;
            if (raw == null) { continue; }
            var ce = CardEntry.fromDict(raw);
            if (ce == null) { continue; }
            var remaining = ce.remaining;
            if (!RugbyTimerCards.isNumeric(remaining)) {
                remaining = RugbyTimerCards.getLiveEntryRemaining(ce, now);
            }
            if (remaining <= 0) { continue; }
            var paused = CardEntry.createFromStartTime(null, ce.duration, ce.label, ce.cardId);
            paused.vibeTriggered = (ce.vibeTriggered == true);
            paused.remaining = remaining;
            pausedList.add(paused.toDict());
        }
        return pausedList;
    }

    static function resumeYellowTimers(list, now) {
        var resumedList = [];
        if (list == null) {
            return resumedList;
        }
        for (var i = 0; i < list.size(); i = i + 1) {
            var raw = list[i] as Lang.Dictionary;
            if (raw == null) { continue; }
            var ce = CardEntry.fromDict(raw);
            if (ce == null) { continue; }
            var duration = ce.duration;
            var remaining = ce.remaining;
            if (!RugbyTimerCards.isNumeric(remaining)) {
                remaining = RugbyTimerCards.getEntryRemaining(ce, now);
            }
            if (!RugbyTimerCards.isNumeric(duration) || remaining <= 0) { continue; }
            if (remaining > duration) { remaining = duration; }
            var elapsed = duration - remaining;
            var resumed = CardEntry.createFromStartTime(now - (elapsed * 1000), duration, ce.label, ce.cardId);
            resumed.vibeTriggered = (ce.vibeTriggered == true);
            resumed.remaining = remaining;
            resumedList.add(resumed.toDict());
        }
        return resumedList;
    }



    /**
     * Computes the highest yellow card label number in a list.
     * @param list The list of yellow card timers
     * @return The highest label number
     */
    static function computeYellowLabelCounter(list) {
        var maxLabel = 0;
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i] as Lang.Dictionary;
            if (entry == null) {
                continue;
            }
            var cardId = entry["cardId"] as Lang.Number;
            if (cardId != null && cardId > maxLabel) {
                maxLabel = cardId;
            }
        }
        return maxLabel;
    }

    /**
     * Parses the number from a yellow card label.
     * @param label The label string (e.g., "Y1")
     * @return The parsed number
     */
    static function parseLabelNumber(label) {
        if (label == null) {
            return 0;
        }
        var digits = label as Lang.String;
        if (digits.length() > 0 && digits[0] == "Y") {
            var trimmed = "";
            for (var idx = 1; idx < digits.length(); idx = idx + 1) {
                trimmed = trimmed + digits[idx];
            }
            digits = trimmed;
        }
        if (digits.length() == 0) {
            return 0;
        }
        try {
            return digits.toLong();
        } catch (ex) {
            System.println("Error parsing yellow card label number: " + ex.getErrorMessage());
            return 0;
        }
    }

    /**
     * Allocates a new yellow card ID.
     * @param model The game model
     * @param isHome A boolean indicating if the card is for the home team
     * @return The new card ID
     */
    static function allocateYellowCardId(model, isHome) {
        if (isHome) {
            model.yellowHomeLabelCounter = model.yellowHomeLabelCounter + 1;
            return model.yellowHomeLabelCounter;
        }
        model.yellowAwayLabelCounter = model.yellowAwayLabelCounter + 1;
        return model.yellowAwayLabelCounter;
    }

    static function allocateRedCardId(model, isHome) {
        if (isHome) {
            model.redHomeLabelCounter = model.redHomeLabelCounter + 1;
            return model.redHomeLabelCounter;
        }
        model.redAwayLabelCounter = model.redAwayLabelCounter + 1;
        return model.redAwayLabelCounter;
    }

    /**
     * Clears all card timers.
     * @param model The game model
     */
    static function clearCardTimers(model) {
        model.yellowHomeTimes = [];
        model.yellowAwayTimes = [];
        model.yellowHomeLabelCounter = 0;
        model.yellowAwayLabelCounter = 0;
        model.redHomeLabelCounter = 0;
        model.redAwayLabelCounter = 0;
        model.redHomeTimes = [];
        model.redAwayTimes = [];
        model.redHomePermanent = false;
        model.redAwayPermanent = false;
        model.yellowHomeTotal = 0;
        model.yellowAwayTotal = 0;
        model.redHomeTotal = 0;
        model.redAwayTotal = 0;
    }
}
