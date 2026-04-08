using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Application.Storage;

/**
 * Settings menu construction only.
 *
 * Responsibility boundary:
 * build the static menu rows from the current profile/storage state while
 * leaving navigation and side effects to the settings delegates.
 */
class RugbySettingsMenu extends WatchUi.Menu2 {
    var profileItem;
    var formatItem;
    var halfTimerItem;
    var conversionItem;
    var penaltyItem;
    var useConvItem;
    var usePenItem;
    var lockStartItem;
    var dimModeItem;
    var idleHintsItem;

    function initialize() {
        Menu2.initialize({:title=>"Rugby Settings"});
        var profile = getActiveProfile();
        var entry = RugbySettingsSupport.getProfileEntry(profile);
        var profileLabel = RugbySettingsSupport.getProfileLabel(profile);
        var formatLabel = RugbySettingsSupport.getFormatLabel(profile);
        var halfLabel = RugbySettingsSupport.getHalfLabel(profile, self);
        var conversionLabel = RugbySettingsSupport.getConversionLabel(profile, self);
        var penaltyLabel = RugbySettingsSupport.getPenaltyLabel(profile, self);
        var useConvLabel = RugbySettingsSupport.getOnOffLabel(entry != null && entry.useConversionTimer);
        var usePenLabel = RugbySettingsSupport.getOnOffLabel(entry != null && entry.usePenaltyTimer);

        profileItem = new WatchUi.MenuItem("Profile", profileLabel, :profile, null);
        addItem(profileItem);

        formatItem = new WatchUi.MenuItem("Format Family", formatLabel, :format_family, null);
        addItem(formatItem);

        halfTimerItem = new WatchUi.MenuItem("Half Timer", halfLabel, :countdown_timer, null);
        addItem(halfTimerItem);

        conversionItem = new WatchUi.MenuItem("Conversion Timer", conversionLabel, :conv_time, null);
        addItem(conversionItem);

        penaltyItem = new WatchUi.MenuItem("Penalty Kick", penaltyLabel, :pen_time, null);
        addItem(penaltyItem);

        useConvItem = new WatchUi.MenuItem("Conversion Overlay", useConvLabel, :use_conv, null);
        addItem(useConvItem);

        usePenItem = new WatchUi.MenuItem("Penalty Overlay", usePenLabel, :use_pen, null);
        addItem(usePenItem);

        var lockStart = Storage.getValue(STORAGE_KEY_LOCK_ON_START);
        if (lockStart == null) { lockStart = false; }
        lockStartItem = new WatchUi.MenuItem("Lock on Start", lockStart ? "On" : "Off", :lock_start, null);
        addItem(lockStartItem);

        var dimMode = Storage.getValue(STORAGE_KEY_DIM_MODE);
        if (dimMode == null) { dimMode = false; }
        dimModeItem = new WatchUi.MenuItem("Dim Theme", dimMode ? "On" : "Off", :dim_mode, null);
        addItem(dimModeItem);

        var showIdleHints = RugbySettingsSupport.getStoredFlag(Storage.getValue(STORAGE_KEY_SHOW_IDLE_HINTS), true);
        idleHintsItem = new WatchUi.MenuItem("Idle Hints", showIdleHints ? "On" : "Off", :idle_hints, null);
        addItem(idleHintsItem);

        addItem(new WatchUi.MenuItem("Reset Scores", null, :reset, null));
    }

    function isInGame() {
        var rugbyApp = Application.getApp() as RugbyTimerApp;
        return rugbyApp != null && rugbyApp.model != null && rugbyApp.model.gameState != STATE_IDLE;
    }

    function getModel() {
        var rugbyApp = Application.getApp() as RugbyTimerApp;
        return rugbyApp.model;
    }

    function getActiveProfile() {
        var model = getModel();
        if (model != null) {
            return model.buildCurrentProfile(model.matchProfileId);
        }
        // Fallback path for cases where the app model is not active yet, such as
        // opening settings outside the normal in-app flow.
        return RugbyMatchProfiles.getProfile(RugbyMatchProfiles.getStoredProfileId());
    }

    function refresh() {
        // Keep the settings menu static after construction to avoid device-specific
        // issues around mutating Menu2 item subtitles at runtime.
    }

    function formatTime(seconds) {
        if (seconds == null) { seconds = 0; }
        var mins = (seconds.toLong() / 60).toLong();
        var secs = (seconds.toLong() % 60).toLong();
        return mins.format("%02d") + ":" + secs.format("%02d");
    }
}
