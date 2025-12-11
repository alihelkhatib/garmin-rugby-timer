using Toybox.Lang;

class RugbyTimerCards {
    static function updateYellowTimers(view, list, delta) {
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

    static function normalizeYellowTimers(view, list, isHome) {
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
                cardId = RugbyTimerCards.allocateYellowCardId(view, isHome);
                label = "Y" + cardId.toString();
            }
            RugbyTimerCards.ensureYellowLabelCounter(view, isHome, cardId);
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

    static function allocateYellowCardId(view, isHome) {
        if (isHome) {
            view.yellowHomeLabelCounter = view.yellowHomeLabelCounter + 1;
            return view.yellowHomeLabelCounter;
        }
        view.yellowAwayLabelCounter = view.yellowAwayLabelCounter + 1;
        return view.yellowAwayLabelCounter;
    }

    static function ensureYellowLabelCounter(view, isHome, cardId) {
        if (cardId == null) {
            return;
        }
        if (isHome) {
            if (cardId > view.yellowHomeLabelCounter) {
                view.yellowHomeLabelCounter = cardId;
            }
        } else {
            if (cardId > view.yellowAwayLabelCounter) {
                view.yellowAwayLabelCounter = cardId;
            }
        }
    }

    static function clearCardTimers(view) {
        view.yellowHomeTimes = [];
        view.yellowAwayTimes = [];
        view.yellowHomeLabelCounter = 0;
        view.yellowAwayLabelCounter = 0;
        view.redHome = 0;
        view.redAway = 0;
        view.redHomePermanent = false;
        view.redAwayPermanent = false;
        view.yellowHomeTotal = 0;
        view.yellowAwayTotal = 0;
        view.redHomeTotal = 0;
        view.redAwayTotal = 0;
    }
}
