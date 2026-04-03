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

    static function create(eventType, isHome) {
        var entry = new ScoreEvent();
        entry.eventType = eventType;
        entry.isHome = isHome == true;
        return entry;
    }

    static function fromDict(raw) {
        if (!(raw instanceof Lang.Dictionary)) {
            return null;
        }
        var entry = new ScoreEvent();
        entry.eventType = raw[:type];
        entry.isHome = raw[:home] == true;
        return entry;
    }

    function toDict() {
        return {
            :type => eventType,
            :home => isHome == true
        };
    }
}
