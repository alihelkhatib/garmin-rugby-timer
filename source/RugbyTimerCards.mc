using Toybox.Lang;
using Toybox.System;

/**
 * A helper class for managing yellow and red card timers.
 */
class RugbyTimerCards {
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
     * @param newGameTime The current timer baseline
     * @return A dictionary containing the updated timers plus an expiry flag
     */
    static function updateYellowTimers(model, list, newGameTime) {
        var newList = [];
        var expiredAny = false;
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i] as Lang.Dictionary;
            if (entry == null) {
                continue;
            }
            var startTime = entry["startTime"] as Lang.Number;
            var duration = entry["duration"] as Lang.Number;
            var remaining = entry["remaining"] as Lang.Number;
            var label = entry["label"] as Lang.String;
            var cardId = entry["cardId"] as Lang.Number;

            if (duration == null) {
                continue;
            }

            if (startTime instanceof Lang.Number) {
                var elapsedTime = (newGameTime - startTime) / 1000.0f;
                remaining = duration - elapsedTime;
            } else if (!(remaining instanceof Lang.Number)) {
                remaining = duration;
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
            newList.add({ "startTime" => startTime, "duration" => duration, "label" => label, "cardId" => cardId, "vibeTriggered" => entry["vibeTriggered"], "remaining" => remaining });
        }
        return {
            "timers" => newList,
            "expired" => expiredAny
        };
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
        model.redHomePermanent = false;
        model.redAwayPermanent = false;
        model.yellowHomeTotal = 0;
        model.yellowAwayTotal = 0;
        model.redHomeTotal = 0;
        model.redAwayTotal = 0;
    }
}
