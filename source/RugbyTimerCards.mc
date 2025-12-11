using Toybox.Lang;

class RugbyTimerCards {
    static function updateYellowTimers(model, list, delta) {
        var newList = [];
        for (var i = 0; i < list.size(); i = i + 1) {
            var rawEntry = list[i];
            var entry = rawEntry as Lang.Dictionary;
            var remaining = null;
            var vibTriggered = false;
            var label = null;
            var cardId = null;
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

    static function normalizeYellowTimers(model, list, isHome) {
        var normalized = [];
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i];
            if (entry == null) {
                continue;
            }
            var dict = entry as Lang.Dictionary;
            var remaining = null;
            var vibTriggered = false;
            var label = null;
            var cardId = null;
            if (dict != null) {
                remaining = dict["remaining"];
                vibTriggered = dict["vibeTriggered"];
                label = dict["label"];
                cardId = dict["cardId"];
            } else {
                remaining = entry;
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

    static function computeYellowLabelCounter(list) {
        var maxLabel = 0;
        for (var i = 0; i < list.size(); i = i + 1) {
            var entry = list[i] as Lang.Dictionary;
            if (entry == null) {
                continue;
            }
            var label = entry["label"];
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

    static function parseLabelNumber(label) {
        if (label == null) {
            return 0;
        }
        var digits = label;
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
            return 0;
        }
    }

    static function allocateYellowCardId(model, isHome) {
        if (isHome) {
            model.yellowHomeLabelCounter = model.yellowHomeLabelCounter + 1;
            return model.yellowHomeLabelCounter;
        }
        model.yellowAwayLabelCounter = model.yellowAwayLabelCounter + 1;
        return model.yellowAwayLabelCounter;
    }

    static function ensureYellowLabelCounter(model, isHome, cardId) {
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

    static function clearCardTimers(model) {
        model.yellowHomeTimes = [];
        model.yellowAwayTimes = [];
        model.yellowHomeLabelCounter = 0;
        model.yellowAwayLabelCounter = 0;
        model.redHome = 0;
        model.redAway = 0;
        model.redHomePermanent = false;
        model.redAwayPermanent = false;
        model.yellowHomeTotal = 0;
        model.yellowAwayTotal = 0;
        model.redHomeTotal = 0;
        model.redAwayTotal = 0;
    }
}
