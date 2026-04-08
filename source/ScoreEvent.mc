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

    static function normalizeEventType(eventType) {
        if (eventType == "try" || eventType == :try) {
            return "try";
        }
        if (eventType == "conversion" || eventType == :conversion) {
            return "conversion";
        }
        if (eventType == "penalty" || eventType == :penalty) {
            return "penalty";
        }
        if (eventType == "drop" || eventType == :drop) {
            return "drop";
        }
        if (eventType == "penalty_try" || eventType == :penalty_try) {
            return "penalty_try";
        }
        return null;
    }

    static function create(eventType, isHome) {
        var entry = new ScoreEvent();
        entry.eventType = ScoreEvent.normalizeEventType(eventType);
        entry.isHome = isHome == true;
        return entry;
    }

    static function fromDict(raw) {
        if (!(raw instanceof Lang.Dictionary)) {
            return null;
        }
        var entry = new ScoreEvent();
        var eventType = raw["type"];
        if (eventType == null) {
            eventType = raw[:type];
        }
        entry.eventType = ScoreEvent.normalizeEventType(eventType);

        var isHome = raw["isHome"];
        if (isHome == null) {
            isHome = raw[:home];
        }
        entry.isHome = isHome == true;
        return entry;
    }

    function toDict() {
        return {
            "type" => eventType,
            "isHome" => isHome == true
        };
    }
}
