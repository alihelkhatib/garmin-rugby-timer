using Toybox.Lang;

/**
 * Typed wrapper for a card timer entry.
 *
 * Purpose: provide a single typed place for card fields and helpers so
 * RugbyTimerCards can use a clearer representation internally while
 * preserving the external dictionary representation used across the app.
 */
class CardEntry {
    var startTime;
    var duration;
    var remaining;
    var label;
    var cardId;
    var vibeTriggered;

    static function fromDict(d) {
        if (!(d instanceof Lang.Dictionary)) { return null; }
        var e = new CardEntry();
        var dict = d as Lang.Dictionary;
        e.startTime = dict["startTime"];
        e.duration = dict["duration"];
        e.remaining = dict["remaining"];
        e.label = dict["label"];
        e.cardId = dict["cardId"];
        e.vibeTriggered = (dict["vibeTriggered"] == true);
        return e;
    }

    static function createFromStartTime(startTime, duration, label, cardId) {
        var e = new CardEntry();
        e.startTime = startTime;
        e.duration = duration;
        e.remaining = duration;
        e.label = label;
        e.cardId = cardId;
        e.vibeTriggered = false;
        return e;
    }

    function toDict() {
        return {
            "startTime" => startTime,
            "duration" => duration,
            "remaining" => remaining,
            "label" => label,
            "cardId" => cardId,
            "vibeTriggered" => (vibeTriggered == true)
        } as Toybox.Lang.Dictionary;
    }
}
