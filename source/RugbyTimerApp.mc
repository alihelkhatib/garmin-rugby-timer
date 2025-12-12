using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Activity;
using Toybox.Position;

/**
 * The main application class for the Rugby Timer.
 * This class is responsible for initializing the application,
 * creating the model, view, and delegate, and handling app-level events.
 */
class RugbyTimerApp extends Application.AppBase {
    // The main view of the application
    var rugbyView;
    // The main delegate of the application
    var rugbyDelegate;
    // The game model
    var model;

    /**
     * Initializes the application.
     */
    function initialize() {
        AppBase.initialize();
    }

    /**
     * This method is called when the application is started.
     * @param state The application state
     */
    function onStart(state) {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition) as Method(info as Position.Info) as Void);
    }

    /**
     * This method is called when the application is stopped.
     * @param state The application state
     */
    function onStop(state) {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition) as Method(info as Position.Info) as Void);
        if (model != null) {
            model.stopRecording();
        }
    }

    /**
     * This method returns the initial view and delegate of the application.
     * @return An array containing the view and delegate
     */
    function getInitialView() {
        model = new RugbyGameModel();
        rugbyView = new RugbyTimerView(model);
        rugbyDelegate = new RugbyTimerDelegate(model);
        return [rugbyView, rugbyDelegate];
    }

    /**
     * This method is called when the GPS position is updated.
     * @param info The position information
     */
    function onPosition(info as Position.Info) as Void {
        if (model != null) {
            model.updatePosition(info);
        }
    }

    /**
     * This method returns the settings view and delegate.
     * @return An array containing the settings view and delegate
     */
    function getSettingsView() {
        return [new RugbySettingsMenu(), new RugbySettingsMenuDelegate()];
    }
}

/**
 * Returns the application instance.
 * @return The application instance
 */
function getApp() {
    return Application.getApp();
}