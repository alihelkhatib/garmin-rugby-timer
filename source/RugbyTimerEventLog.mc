using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.WatchUi;

const EVENT_LOG_LIMIT = 64;
const EVENT_LOG_STORAGE_KEY = STORAGE_KEY_EVENT_LOG_EXPORT;

/**
 * Event-log formatting, persistence, and simple viewer support.
 *
 * Purpose: keep human-readable match-event history logic separate from the
 * gameplay model and from the menu/delegate code that exposes it.
 */
class RugbyTimerEventLog {

    static function buildEventLogLines(model) {
        var lines = [];
        var entries = model.eventLogEntries;
        if (!(entries instanceof Lang.Array)) {
            return lines;
        }
        for (var i = 0; i < entries.size(); i = i + 1) {
            var entry = EventLogEntry.fromDict(entries[i]);
            if (entry == null) {
                continue;
            }
            lines.add(entry.toDisplayString());
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
        model.eventLogEntries.add(EventLogEntry.create(timestamp, description).toDict());
        if (model.eventLogEntries.size() > EVENT_LOG_LIMIT) {
            model.eventLogEntries.remove(0);
        }
    }

    static function exportEventLog(model) {
        var text = RugbyTimerEventLog.buildEventLogText(model);
        RugbyStorageSupport.setValue(EVENT_LOG_STORAGE_KEY, text);
    }

    static function showEventLog(model) {
        WatchUi.pushView(new EventLogMenu(model.eventLogEntries), new EventLogDelegate(model), WatchUi.SLIDE_UP);
    }
}
