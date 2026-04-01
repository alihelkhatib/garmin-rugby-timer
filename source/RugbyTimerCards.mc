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

    static function getEntryRemaining(entry, now) {
        if (entry == null) {
            return 0;
        }
        var duration = entry["duration"];
        var startTime = entry["startTime"];
        // Timer is live: integer division keeps result as Lang.Number (not Float),
        // which is required for instanceof checks in clampRemaining and formatShortTime.
        if (RugbyTimerCards.isNumeric(startTime) && RugbyTimerCards.isNumeric(duration)) {
            var elapsedSecs = (now - startTime) / 1000;
            if (elapsedSecs < 0) { elapsedSecs = 0; }
            var remaining = duration - elapsedSecs;
            if (remaining < 0) { remaining = 0; }
            if (remaining > duration) { remaining = duration; }
            return remaining;
        }
        // Timer is paused/frozen: use stored remaining.
        var stored = entry["remaining"];
        if (RugbyTimerCards.isNumeric(stored) && stored > 0) {
            return stored;
        }
        // Fallback: return full duration so a fresh card never shows '--'.
        if (RugbyTimerCards.isNumeric(duration)) {
            return duration;
        }
        return 0;
    }

    static function getLiveEntryRemaining(entry, now) {
        return RugbyTimerCards.getEntryRemaining(entry, now);
    }

    /**
     * Creates a yellow card entry from a start time and other details.
     * @param startTime The start time of the card
     * @param duration The total duration of the card
     * @param label The label for the card (e.g., "Y1")
     * @param cardId The ID of the card
     * @param vibeTriggered A boolean indicating if the vibration has been triggered for this card
     * @return A dictionary representing the yellow card entry
     */
    static function createYellowCardEntryFromStartTime(startTime, duration, label, cardId) {
        return {
            "startTime" => startTime,
            "duration" => duration,
            "remaining" => duration,
            "label" => label,
            "cardId" => cardId,
            "vibeTriggered" => false
        };
    }

    /**
     * Updates the yellow card timers.
     * @param model The game model
     * @param list The list of yellow card timers
     * @param deltaSeconds The elapsed seconds since the previous update tick
     * @return A dictionary containing the updated timers plus an expiry flag
     */
    static function updateYellowTimers(model, list, deltaSeconds) {
        var newList = [];
        var expiredAny = false;
        if (!RugbyTimerCards.isNumeric(deltaSeconds) || deltaSeconds < 0) {
            deltaSeconds = 0;
        }
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i] as Lang.Dictionary;
            if (entry == null) {
                continue;
            }
            var duration = entry["duration"];
            var startTime = entry["startTime"];
            var storedRemaining = entry["remaining"];

            if (!RugbyTimerCards.isNumeric(duration) && RugbyTimerCards.isNumeric(storedRemaining)) {
                duration = storedRemaining;
            }

            if (!RugbyTimerCards.isNumeric(duration)) {
                continue;
            }
            var remaining;
            if (RugbyTimerCards.isNumeric(storedRemaining)) {
                remaining = storedRemaining;
            } else {
                remaining = duration;
            }

            if (RugbyTimerCards.isNumeric(startTime)) {
                remaining = remaining - deltaSeconds;
            }
            remaining = RugbyTimerCards.clampRemaining(remaining, duration);

            // Safety: never expire a card within the first 2 seconds of creation.
            if (remaining <= 0) {
                if (startTime instanceof Lang.Number) {
                    var ageMs = System.getTimer() - startTime;
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

            entry["vibeTriggered"] = entry["vibeTriggered"] == true;
            if (!entry["vibeTriggered"] && remaining <= 10) {
                entry["vibeTriggered"] = true;
                RugbyTimerTiming.triggerYellowTimerWarningVibe();
            }
            entry["remaining"] = remaining;
            newList.add(entry);
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
            var entry = list[i] as Lang.Dictionary;
            if (entry == null) {
                continue;
            }
            var remaining = entry["remaining"];
            if (!RugbyTimerCards.isNumeric(remaining)) {
                remaining = RugbyTimerCards.getLiveEntryRemaining(entry, now);
            }
            if (remaining <= 0) {
                continue;
            }
            pausedList.add({
                "startTime" => null,
                "duration" => entry["duration"],
                "label" => entry["label"],
                "cardId" => entry["cardId"],
                "vibeTriggered" => entry["vibeTriggered"] == true,
                "remaining" => remaining
            });
        }
        return pausedList;
    }

    static function resumeYellowTimers(list, now) {
        var resumedList = [];
        if (list == null) {
            return resumedList;
        }
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i] as Lang.Dictionary;
            if (entry == null) {
                continue;
            }
            var duration = entry["duration"];
            var remaining = entry["remaining"];
            if (!RugbyTimerCards.isNumeric(remaining)) {
                remaining = RugbyTimerCards.getEntryRemaining(entry, now);
            }
            if (!RugbyTimerCards.isNumeric(duration) || remaining <= 0) {
                continue;
            }
            if (remaining > duration) { remaining = duration; }
            var elapsed = duration - remaining;
            resumedList.add({
                "startTime" => now - (elapsed * 1000),
                "duration" => duration,
                "label" => entry["label"],
                "cardId" => entry["cardId"],
                "vibeTriggered" => entry["vibeTriggered"] == true,
                "remaining" => remaining
            });
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

    /**
     * Clears all card timers.
     * @param model The game model
     */
    static function clearCardTimers(model) {
        model.yellowHomeTimes = [];
        model.yellowAwayTimes = [];
        model.yellowHomeLabelCounter = 0;
        model.yellowAwayLabelCounter = 0;
        model.redHome = null;
        model.redAway = null;
        model.redHomePausedRemaining = null;
        model.redAwayPausedRemaining = null;
        model.redHomePermanent = false;
        model.redAwayPermanent = false;
        model.yellowHomeTotal = 0;
        model.yellowAwayTotal = 0;
        model.redHomeTotal = 0;
        model.redAwayTotal = 0;
    }
}
