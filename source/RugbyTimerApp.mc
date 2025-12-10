using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Activity;
using Toybox.Position;

class RugbyTimerApp extends Application.AppBase {
    var rugbyView;
    var rugbyDelegate;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition) as Method(info as Position.Info) as Void);
    }

    function onStop(state) {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition) as Method(info as Position.Info) as Void);
        if (rugbyView != null) {
            rugbyView.stopRecording();
        }
    }

    function getInitialView() {
        rugbyView = new RugbyTimerView();
        rugbyDelegate = new RugbyTimerDelegate(rugbyView);
        return [rugbyView, rugbyDelegate];
    }

    function onPosition(info as Position.Info) as Void {
        if (rugbyView != null) {
            rugbyView.updatePosition(info);
        }
    }

    function getSettingsView() {
        return [new RugbySettingsMenu(), new RugbySettingsMenuDelegate()];
    }
}

function getApp() {
    return Application.getApp();
}
