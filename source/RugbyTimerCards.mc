using Toybox.Lang;

/**
 * A helper class for managing yellow and red card timers.
 */
class RugbyTimerCards {
    /**
     * Updates the yellow card timers.
     * @param model The game model
     * @param list The list of yellow card timers
     * @param delta The time delta since the last update
     * @return The updated list of yellow card timers
     */
    static function updateYellowTimers(model as RugbyGameModel, list as Array<Dictionary>, delta as Float) as Array<Dictionary> {
        var newList = [];
        for (var i = 0; i < list.size(); i = i + 1) {
            var rawEntry = list[i];
            var entry = rawEntry as Lang.Dictionary or Null;
            var remaining;
            var vibTriggered;
            var label;
            var cardId;
            if (entry != null) {
                remaining = entry["remaining"];
                vibTriggered = entry["vibeTriggered"];
                label = entry["label"];
                cardId = entry["cardId"];
            } else {
                remaining = rawEntry;
            }
            if (remaining == null) {
                continue;
            }
            remaining = remaining - delta;
            if (remaining <= 0) {
                continue;
            }
            vibTriggered = vibTriggered == true;
            if (!vibTriggered && remaining <= 10) {
                vibTriggered = true;
                RugbyTimerTiming.triggerYellowTimerVibe();
            }
            newList.add({ "remaining" => remaining, "vibeTriggered" => vibTriggered, "label" => label, "cardId" => cardId });
        }
        return newList;
    }

    /**
     * Normalizes the yellow card timers.
     * This is used to ensure that the data structure is consistent after being loaded from storage.
     * @param model The game model
     * @param list The list of yellow card timers
     * @param isHome A boolean indicating if the timers are for the home team
     * @return The normalized list of yellow card timers
     */
    /**
     * Normalizes the yellow card timers.
     * This is used to ensure that the data structure is consistent after being loaded from storage.
     * @param model The game model
     * @param list The list of yellow card timers
     * @param isHome A boolean indicating if the timers are for the home team
     * @return The normalized list of yellow card timers
     */
    static function normalizeYellowTimers(model as RugbyGameModel, list as Array<Any>, isHome as Boolean) as Array<Dictionary> {
        var normalized = [];
        for (var i = 0; i < list.size(); i = i + 1) {
            var rawEntry = list[i];
            var dict = rawEntry as Lang.Dictionary or Null;
            var remaining;
            var vibTriggered;
            var label;
            var cardId;
            if (dict != null) {
                remaining = dict["remaining"];
                vibTriggered = dict["vibeTriggered"];
                label = dict["label"];
                cardId = dict["cardId"];
            } else {
                remaining = rawEntry;
            }
            if (remaining == null) {
                continue;
            }
            vibTriggered = vibTriggered == true;
            if (cardId == null && label != null) {
                cardId = RugbyTimerCards.parseLabelNumber(label);
            }
            if (label == null && cardId != null) {
                label = "Y" + cardId.toString();
            }
            if ((label == null || cardId == null)) {
                cardId = RugbyTimerCards.allocateYellowCardId(model, isHome);
                label = "Y" + cardId.toString();
            }
            RugbyTimerCards.ensureYellowLabelCounter(model, isHome, cardId);
            normalized.add({ "remaining" => remaining, "vibeTriggered" => vibTriggered, "label" => label, "cardId" => cardId });
        }
        return normalized;
    }

    /**
     * Computes the highest yellow card label number in a list.
     * @param list The list of yellow card timers
     * @return The highest label number
     */
    static function computeYellowLabelCounter(list as Array<Dictionary>) as Number {
        var maxLabel = 0;
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i] as Lang.Dictionary or Null;
            if (entry == null) {
                continue;
            }
            var label = entry["label"] as String or Null;
            if (label == null) {
                continue;
            }
            var labelNumber = RugbyTimerCards.parseLabelNumber(label);
            if (labelNumber > maxLabel) {
                maxLabel = labelNumber;
            }
        }
        return maxLabel;
    }

    /**
     * Parses the number from a yellow card label.
     * @param label The label string (e.g., "Y1")
     * @return The parsed number
     */
    static function parseLabelNumber(label as String or Null) as Number {
        if (label == null) {
            return 0;
        }
        var digits = label as String;
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
            return digits.toLong() as Number;
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
    static function allocateYellowCardId(model as RugbyGameModel, isHome as Boolean) as Number {
        if (isHome) {
            model.yellowHomeLabelCounter = model.yellowHomeLabelCounter + 1;
            return model.yellowHomeLabelCounter;
        }
        model.yellowAwayLabelCounter = model.yellowAwayLabelCounter + 1;
        return model.yellowAwayLabelCounter;
    }

    /**
     * Ensures that the yellow card label counter is up to date.
     * @param model The game model
     * @param isHome A boolean indicating if the card is for the home team
     * @param cardId The card ID
     */
    static function ensureYellowLabelCounter(model as RugbyGameModel, isHome as Boolean, cardId as Number or Null) as Void {
        if (cardId == null) {
            return;
        }
        if (isHome) {
            if (cardId > model.yellowHomeLabelCounter) {
                model.yellowHomeLabelCounter = cardId;
            }
        }
        else {
            if (cardId > model.yellowAwayLabelCounter) {
                model.yellowAwayLabelCounter = cardId;
            }
        }
    }

    /**
     * Clears all card timers.
     * @param model The game model
     */
    static function clearCardTimers(model as RugbyGameModel) as Void {
        model.yellowHomeTimes = [];
        model.yellowAwayTimes = [];
        model.yellowHomeLabelCounter = 0;
        model.yellowAwayLabelCounter = 0;
        model.redHome = 0.0f;
        model.redAway = 0.0f;
        model.redHomePermanent = false;
        model.redAwayPermanent = false;
        model.yellowHomeTotal = 0;
        model.yellowAwayTotal = 0;
        model.redHomeTotal = 0;
        model.redAwayTotal = 0;
    }
}