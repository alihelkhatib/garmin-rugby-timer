using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.WatchUi;

class RugbyTimerEventLog {
    const EVENT_LOG_LIMIT = 64;
    const EVENT_LOG_STORAGE_KEY = "eventLogExport";

    static function buildEventLogLines(view) {
        var lines = [];
        if (view.eventLogEntries == null) {
            return lines;
        }
        for (var i = 0; i < view.eventLogEntries.size(); i = i + 1) {
            var entry = view.eventLogEntries[i] as Lang.Dictionary;
            if (entry == null) {
                continue;
            }
            var time = entry[:time];
            var desc = entry[:desc];
            lines.add((time != null ? time : "--:--") + " – " + (desc != null ? desc : ""));
        }
        return lines;
    }

    static function buildEventLogText(view) {
        var lines = RugbyTimerEventLog.buildEventLogLines(view);
        var text = "";
        for (var i = 0; i < lines.size(); i = i + 1) {
            if (i > 0) { text = text + "\n"; }
            text = text + lines[i];
        }
        return text;
    }

    static function appendEntry(view, description) {
        if (description == null) {
            return;
        }
        if (view.eventLogEntries == null) {
            view.eventLogEntries = [];
        }
        var timestamp = view.formatTime(view.gameTime);
        view.eventLogEntries.add({:time => timestamp, :desc => description});
        if (view.eventLogEntries.size() > EVENT_LOG_LIMIT) {
            view.eventLogEntries.remove(0);
        }
    }

    static function exportEventLog(view) {
        var text = RugbyTimerEventLog.buildEventLogText(view);
        Storage.setValue(EVENT_LOG_STORAGE_KEY, text);
    }

    static function showEventLog(view) {
        WatchUi.pushView(new EventLogMenu(view.eventLogEntries), new EventLogDelegate(view), WatchUi.SLIDE_UP);
    }
}
