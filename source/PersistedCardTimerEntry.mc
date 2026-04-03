using Toybox.Lang;

/**
 * Serialized sanction-timer shape stored inside persisted match snapshots.
 *
 * Purpose: describe the storage-only card-timer payload separately from the
 * runtime `CardEntry` object used during live updates.
 */
class PersistedCardTimerEntry {
    var duration;
    var clockStart;
    var remaining;
    var label;
    var cardId;
    var vibeTriggered;

    static function fromDict(raw) {
        if (!(raw instanceof Lang.Dictionary)) {
            return null;
        }
        var dict = raw as Lang.Dictionary;
        var entry = new PersistedCardTimerEntry();
        entry.duration = dict["duration"];
        entry.clockStart = dict["clockStart"];
        entry.remaining = dict["remaining"];
        entry.label = dict["label"];
        entry.cardId = dict["cardId"];
        entry.vibeTriggered = dict["vibeTriggered"] == true;
        return entry;
    }

    static function create(duration, clockStart, remaining, label, cardId, vibeTriggered) {
        var entry = new PersistedCardTimerEntry();
        entry.duration = duration;
        entry.clockStart = clockStart;
        entry.remaining = remaining;
        entry.label = label;
        entry.cardId = cardId;
        entry.vibeTriggered = vibeTriggered == true;
        return entry;
    }

    function toDict() {
        return {
            "duration" => duration,
            "clockStart" => clockStart,
            "remaining" => remaining,
            "label" => label,
            "cardId" => cardId,
            "vibeTriggered" => vibeTriggered == true
        };
    }
}
