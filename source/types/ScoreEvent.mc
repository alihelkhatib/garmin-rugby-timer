using Toybox.Lang;

/**
 * Typed wrapper for two-value score/history style payloads.
 *
 * Purpose: keep score-event history and undo payload access explicit while the
 * surrounding history storage remains dictionary-based for compatibility.
 */
class ScoreEvent {
    var eventType;
    var isHome;

    static function normalizeTypeKey(eventType) {
        if (eventType == null) {
            return null;
        }

        var typeText = eventType.toString();
        if (typeText == "try" || typeText == ":try") { return "try"; }
        if (typeText == "conversion" || typeText == ":conversion") { return "conversion"; }
        if (typeText == "penalty_try" || typeText == ":penalty_try") { return "penalty_try"; }
        if (typeText == "penalty" || typeText == ":penalty") { return "penalty"; }
        if (typeText == "drop" || typeText == ":drop") { return "drop"; }
        return null;
    }

    static function create(eventType, isHome) {
        var normalizedType = ScoreEvent.normalizeTypeKey(eventType);
        if (normalizedType == null) {
            return null;
        }
        var entry = new ScoreEvent();
        entry.eventType = normalizedType;
        entry.isHome = isHome == true;
        return entry;
    }

    static function fromDict(raw) {
        if (!(raw instanceof Lang.Dictionary)) {
            return null;
        }
        var entry = new ScoreEvent();
        var typeValue = raw["type"];
        if (typeValue == null) {
            typeValue = raw[:type];
        }
        entry.eventType = ScoreEvent.normalizeTypeKey(typeValue);
        entry.isHome = raw["home"] == true;
        if (entry.isHome != true) {
            entry.isHome = raw[:home] == true;
        }
        if (entry.eventType == null) {
            return null;
        }
        return entry;
    }

    function toDict() {
        return {
            "type" => ScoreEvent.normalizeTypeKey(eventType),
            "home" => isHome == true
        };
    }

    function isType(eventTypeToMatch) {
        return ScoreEvent.normalizeTypeKey(eventType) == ScoreEvent.normalizeTypeKey(eventTypeToMatch);
    }
}
