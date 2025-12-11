using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Activity;
using Toybox.Position;

class RugbyTimerApp extends Application.AppBase {
    var rugbyView;
    var rugbyDelegate;
    var model;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition) as Method(info as Position.Info) as Void);
    }

    function onStop(state) {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition) as Method(info as Position.Info) as Void);
        if (model != null) {
            model.stopRecording();
        }
    }

    function getInitialView() {
        model = new RugbyGameModel();
        rugbyView = new RugbyTimerView(model);
        rugbyDelegate = new RugbyTimerDelegate(model);
        return [rugbyView, rugbyDelegate];
    }

    function onPosition(info as Position.Info) as Void {
        if (model != null) {
            model.updatePosition(info);
        }
    }

    function getSettingsView() {
        return [new RugbySettingsMenu(), new RugbySettingsMenuDelegate()];
    }
}

function getApp() {
    return Application.getApp();
}
