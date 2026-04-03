using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Activity;
using Toybox.Position;
using Toybox.System;

/**
 * Application entrypoint for the watch app.
 *
 * Purpose: construct and retain the shared `RugbyGameModel`, `RugbyTimerView`,
 * and `RugbyTimerDelegate` instances, then forward app lifecycle events to them.
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
        try {
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition) as Method(info as Position.Info) as Void);
        } catch (ex) {
            System.println("Unable to enable location events: " + ex.getErrorMessage());
        }
    }

    /**
     * This method is called when the application is stopped.
     * @param state The application state
     */
    function onStop(state) {
        try {
            Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition) as Method(info as Position.Info) as Void);
        } catch (ex) {
            System.println("Unable to disable location events: " + ex.getErrorMessage());
        }
        if (model != null) {
            model.handleAppStop();
        }
    }

    /**
     * Ensure the shared game model exists and has loaded persisted settings/state.
     *
     * Purpose: settings and the main view must operate on the same initialized
     * model so preset changes immediately affect the active countdown/profile.
     */
    function ensureModelReady() {
        if (model == null) {
            model = new RugbyGameModel();
            model.initialize();
        }
        return model;
    }

    /**
     * This method returns the initial view and delegate of the application.
     * @return An array containing the view and delegate
     */
    function getInitialView() {
        var activeModel = ensureModelReady();
        rugbyView = new RugbyTimerView(activeModel);
        rugbyDelegate = new RugbyTimerDelegate(activeModel);
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
        ensureModelReady();
        var menu = new RugbySettingsMenu();
        return [menu, new RugbySettingsMenuDelegate(menu, false)];
    }
}

/**
 * Returns the application instance.
 * @return The application instance
 */
function getApp() {
    return Application.getApp();
}
