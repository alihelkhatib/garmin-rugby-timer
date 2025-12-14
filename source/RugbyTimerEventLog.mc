using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.WatchUi;

const EVENT_LOG_LIMIT = 64;
const EVENT_LOG_STORAGE_KEY = "eventLogExport";

class RugbyTimerEventLog {

    static function buildEventLogLines(model) {
        var lines = [];
        if (model.eventLogEntries == null) {
            return lines;
        }
        for (var i = 0; i < model.eventLogEntries.size(); i = i + 1) {
            var entry = model.eventLogEntries[i] as Lang.Dictionary;
            if (entry == null) {
                continue;
            }
            var time = entry[:time] as Lang.String;
            var desc = entry[:desc] as Lang.String;
            lines.add((time != null ? time : "--:--") + " – " + (desc != null ? desc : ""));
        }
        return lines;
    }

    static function buildEventLogText(model) {
        var lines = RugbyTimerEventLog.buildEventLogLines(model);
        var text = "";
        for (var i = 0; i < lines.size(); i = i + 1) {
            if (i > 0) { text = text + "\n"; }
            text = text + (lines[i] as Lang.String);
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
        model.eventLogEntries.add({:time => timestamp, :desc => description});
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
