using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.WatchUi;
using Rez.Strings;

const EVENT_LOG_LIMIT = 16;
const EVENT_LOG_STORAGE_KEY = STORAGE_KEY_EVENT_LOG_EXPORT;

/**
 * Event-log formatting, persistence, and simple viewer support.
 *
 * Purpose: keep human-readable match-event history logic separate from the
 * gameplay model and from the menu/delegate code that exposes it.
 */
class RugbyTimerEventLog {
    static function createStoredEntry(time, description) {
        return {
            "time" => time,
            "description" => description
        };
    }

    static function getStoredEntryTime(raw) {
        if (!(raw instanceof Lang.Dictionary)) {
            return null;
        }
        var time = raw["time"];
        if (time == null) {
            time = raw[:time];
        }
        return time;
    }

    static function getStoredEntryDescription(raw) {
        if (!(raw instanceof Lang.Dictionary)) {
            return null;
        }
        var description = raw["description"];
        if (description == null) {
            description = raw["desc"];
        }
        if (description == null) {
            description = raw[:description];
        }
        if (description == null) {
            description = raw[:desc];
        }
        return description;
    }

    static function formatStoredEntry(raw) {
        var time = RugbyTimerEventLog.getStoredEntryTime(raw);
        var description = RugbyTimerEventLog.getStoredEntryDescription(raw);
        if (time == null) { time = RugbyStrings.load(Rez.Strings.EventLog_NoTime); }
        if (description == null) { description = ""; }
        return time + " – " + description;
    }

    static function buildEventLogLines(model) {
        var lines = [];
        var entries = model.eventLogEntries;
        if (!(entries instanceof Lang.Array)) {
            return lines;
        }
        for (var i = 0; i < entries.size(); i = i + 1) {
            var line = RugbyTimerEventLog.formatStoredEntry(entries[i]);
            if (line == null) {
                continue;
            }
            lines.add(line);
        }
        return lines;
    }

    static function buildEventLogText(model) {
        var lines = RugbyTimerEventLog.buildEventLogLines(model) as Lang.Array;
        var text = "";
        for (var i = 0; i < lines.size(); i = i + 1) {
            if (i > 0) { text = text + "\n"; }
            var line = lines[i] as Lang.String;
            if (line != null) {
                text = text + line;
            }
        }
        return text;
    }

    static function appendEntry(model, description) {
        if (description == null) {
            return;
        }
        if (model.eventLogEntries == null) {
            model.eventLogEntries = [];
        }
        var timestamp = RugbyTimerTiming.formatTime(model.gameTime);
        model.eventLogEntries.add(RugbyTimerEventLog.createStoredEntry(timestamp, description));
        if (model.eventLogEntries.size() > EVENT_LOG_LIMIT) {
            model.eventLogEntries.remove(0);
        }
    }

    static function exportEventLog(model) {
        var text = RugbyTimerEventLog.buildEventLogText(model);
        Storage.setValue(EVENT_LOG_STORAGE_KEY, text);
    }

    static function showEventLog(model) {
        WatchUi.pushView(new EventLogMenu(model.eventLogEntries), new EventLogDelegate(model), WatchUi.SLIDE_UP);
    }
}

