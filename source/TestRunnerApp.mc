using Toybox.Application;
using Toybox.System;
using Toybox.WatchUi;

/**
 * Test runner application entrypoint for CI/local tests.
 *
 * Purpose: provide the minimal app shell required by the Garmin unit-test
 * target without dragging the full runtime UI into test builds.
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
        // Tests are executed via the SDK unit test runner (use --unit-test and monkeydo /t)
        System.println("TestRunnerApp started. Use SDK unit-test runner to execute tests.");
    }

    function getInitialView() {
        // Minimal placeholder view and delegate so the app can start
        var v = new WatchUi.View();
        var d = new WatchUi.BehaviorDelegate();
        return [v, d];
    }
}
