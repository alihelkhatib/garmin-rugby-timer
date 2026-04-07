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
        if (!(desc instanceof Lang.String) || desc.length() == 0) {
            return null;
        }
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
        entry.time = raw["time"];
        if (entry.time == null) {
            entry.time = raw[:time];
        }
        entry.desc = raw["desc"];
        if (entry.desc == null) {
            entry.desc = raw[:desc];
        }
        if (!(entry.time instanceof Lang.String) || !(entry.desc instanceof Lang.String) || entry.desc.length() == 0) {
            return null;
        }
        return entry;
    }

    function toDict() {
        return {
            "time" => time,
            "desc" => desc
        };
    }

    function toDisplayString() {
        return (time != null ? time : "--:--") + " – " + (desc != null ? desc : "");
    }
}
