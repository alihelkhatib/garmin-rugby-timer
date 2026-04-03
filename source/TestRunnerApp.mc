using Toybox.Application;
using Toybox.System;
using Toybox.WatchUi;

/**
 * Test runner application entrypoint for CI/local tests.
 */
class TestRunnerApp extends Application.AppBase {
    // Keep the same public fields referenced by other modules to satisfy compile-time checks
    var rugbyView;
    var rugbyDelegate;
    var model;
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        // Run tests immediately on start
        try {
            TestRunner.runAll();
        } catch (ex) {
            System.println("Error while running tests: " + ex.getErrorMessage());
        }
    }

    function getInitialView() {
        // Minimal placeholder view and delegate so the app can start
        var v = new WatchUi.View();
        var d = new WatchUi.BehaviorDelegate();
        return [v, d];
    }
}
