using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.WatchUi;

const EVENT_LOG_LIMIT = 64;
const EVENT_LOG_STORAGE_KEY = "eventLogExport";

class RugbyTimerEventLog {

    static function buildEventLogLines(model as RugbyGameModel) as Array<String> {
        var lines = [] as Array<String>;
        if (model.eventLogEntries == null) {
            return lines;
        }
        for (var i as Number = 0; i < model.eventLogEntries.size(); i = i + 1) {
            var entry = model.eventLogEntries[i] as Lang.Dictionary or Null;
            if (entry == null) {
                continue;
            }
            var time = entry[:time] as String or Null;
            var desc = entry[:desc] as String or Null;
            lines.add((time != null ? time : "--:--") + " – " + (desc != null ? desc : ""));
        }
        return lines;
    }

    static function buildEventLogText(model as RugbyGameModel) as String {
        var lines = RugbyTimerEventLog.buildEventLogLines(model) as Array<String>;
        var text as String = "";
        for (var i as Number = 0; i < lines.size(); i = i + 1) {
            if (i > 0) { text = text + "\n"; }
            text = text + lines[i];
        }
        return text;
    }

    static function appendEntry(model as RugbyGameModel, description as String or Null) as Void {
        if (description == null) {
            return;
        }
        if (model.eventLogEntries == null) {
            model.eventLogEntries = [] as Array<Dictionary>;
        }
        var timestamp = RugbyTimerTiming.formatTime(model.gameTime);
        model.eventLogEntries.add({:time => timestamp, :desc => description} as Dictionary);
        if (model.eventLogEntries.size() > EVENT_LOG_LIMIT) {
            model.eventLogEntries.remove(0);
        }
    }

    static function exportEventLog(model as RugbyGameModel) as Void {
        var text = RugbyTimerEventLog.buildEventLogText(model) as String;
        Storage.setValue(EVENT_LOG_STORAGE_KEY, text);
    }

    static function showEventLog(model as RugbyGameModel) as Void {
        WatchUi.pushView(new EventLogMenu(model.eventLogEntries), new EventLogDelegate(model), WatchUi.SLIDE_UP);
    }
}
