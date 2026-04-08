using Toybox.Lang;

/**
 * Typed wrapper for one human-readable event-log entry.
 *
 * The storage schema stays dictionary-based for compatibility; this wrapper
 * keeps the formatting and field access in one place.
 */
class EventLogEntry {
    var time;
    var desc;

    static function create(time, desc) {
        var entry = new EventLogEntry();
        entry.time = time;
        entry.desc = desc;
        return entry;
    }

    static function fromDict(raw) {
        if (!(raw instanceof Lang.Dictionary)) {
            return null;
        }
        var entry = new EventLogEntry();
        var time = raw["time"];
        if (time == null) {
            time = raw[:time];
        }
        var desc = raw["description"];
        if (desc == null) {
            desc = raw["desc"];
        }
        if (desc == null) {
            desc = raw[:description];
        }
        if (desc == null) {
            desc = raw[:desc];
        }
        entry.time = time;
        entry.desc = desc;
        return entry;
    }

    function toDict() {
        return {
            "time" => time,
            "description" => desc
        };
    }

    function toDisplayString() {
        return (time != null ? time : "--:--") + " – " + (desc != null ? desc : "");
    }
}
