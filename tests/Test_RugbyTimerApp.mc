using Toybox.Test;
using Toybox.Lang;

/*
Unit tests for `RugbyTimerApp` lifecycle/model initialization behavior.

Purpose: verify the shared game model is initialized once and reused across
settings and main-view entrypoints so preset changes are not lost.
*/
(:test)
function test_app_reuses_initialized_model_across_settings_and_main_view(logger as Test.Logger) as Lang.Boolean {
    clearCustomStorage();
    clearSavedGameStorage();

    var app = new RugbyTimerApp();
    app.initialize();
    var model = app.ensureModelReady();
    model.setMatchProfile("7s");

    app.getInitialView();

    if (app.model == null) {
        logger.error("app model missing after getInitialView");
        return false;
    }
    if (app.model.matchProfileId != "7s") {
        logger.error("selected profile was not preserved");
        return false;
    }
    return app.model.countdownTimer == 420 && app.model.countdownRemaining == 420;
}
