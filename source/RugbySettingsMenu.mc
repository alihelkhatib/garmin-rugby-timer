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
    const ROW_MATCH_FORMAT = 0;
    const ROW_CONVERSION_TIMER = 1;
    const ROW_PENALTY_TIMER = 2;
    const ROW_USE_CONVERSION = 3;
    const ROW_USE_PENALTY = 4;
    const ROW_TEAM_LABELS = 5;
    const ROW_LOCK_ON_START = 6;
    const ROW_DIM_THEME = 7;

    var formatItem;
    var conversionItem;
    var penaltyItem;
    var useConvItem;
    var usePenItem;
    var teamLabelsItem;
    var lockStartItem;
    var dimModeItem;

    function initialize() {
        Menu2.initialize({:title=>"Rugby Settings"});
        var model = getModel();
        var profile = getActiveProfile();
        var matchFormatLabel = getMatchFormatLabel();
        var conversionLabel = getConversionLabel();
        var penaltyLabel = getPenaltyLabel();
        var useConvLabel = RugbySettingsSupport.getOnOffLabel(model != null ? model.useConversionTimer : RugbySettingsSupport.getProfileEntry(profile) != null && RugbySettingsSupport.getProfileEntry(profile).useConversionTimer);
        var usePenLabel = RugbySettingsSupport.getOnOffLabel(model != null ? model.usePenaltyTimer : RugbySettingsSupport.getProfileEntry(profile) != null && RugbySettingsSupport.getProfileEntry(profile).usePenaltyTimer);
        var teamLabelsLabel = getTeamLabelModeLabel();

        formatItem = new WatchUi.MenuItem("Match Format", matchFormatLabel, :format_family, null);
        addItem(formatItem);

        conversionItem = new WatchUi.MenuItem("Conversion Timer", conversionLabel, :conv_time, null);
        addItem(conversionItem);

        penaltyItem = new WatchUi.MenuItem("Penalty Kick", penaltyLabel, :pen_time, null);
        addItem(penaltyItem);

        useConvItem = new WatchUi.MenuItem("Conversion Overlay", useConvLabel, :use_conv, null);
        addItem(useConvItem);

        usePenItem = new WatchUi.MenuItem("Penalty Overlay", usePenLabel, :use_pen, null);
        addItem(usePenItem);

        teamLabelsItem = new WatchUi.MenuItem("Team Labels", teamLabelsLabel, :team_labels, null);
        addItem(teamLabelsItem);

        var lockStart = Storage.getValue(STORAGE_KEY_LOCK_ON_START);
        if (lockStart == null) { lockStart = false; }
        lockStartItem = new WatchUi.MenuItem("Lock on Start", lockStart ? "On" : "Off", :lock_start, null);
        addItem(lockStartItem);

        var dimMode = Storage.getValue(STORAGE_KEY_DIM_MODE);
        if (dimMode == null) { dimMode = false; }
        dimModeItem = new WatchUi.MenuItem("Dim Theme", dimMode ? "On" : "Off", :dim_mode, null);
        addItem(dimModeItem);

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
        var model = getModel();
        var lockStart = Storage.getValue(STORAGE_KEY_LOCK_ON_START);
        var dimMode = Storage.getValue(STORAGE_KEY_DIM_MODE);

        if (lockStart == null) { lockStart = false; }
        if (dimMode == null) { dimMode = false; }

        updateSubLabel(formatItem, ROW_MATCH_FORMAT, getMatchFormatLabel());
        updateSubLabel(conversionItem, ROW_CONVERSION_TIMER, getConversionLabel());
        updateSubLabel(penaltyItem, ROW_PENALTY_TIMER, getPenaltyLabel());
        updateSubLabel(useConvItem, ROW_USE_CONVERSION, RugbySettingsSupport.getOnOffLabel(model != null && model.useConversionTimer));
        updateSubLabel(usePenItem, ROW_USE_PENALTY, RugbySettingsSupport.getOnOffLabel(model != null && model.usePenaltyTimer));
        updateSubLabel(teamLabelsItem, ROW_TEAM_LABELS, getTeamLabelModeLabel());
        updateSubLabel(lockStartItem, ROW_LOCK_ON_START, lockStart ? "On" : "Off");
        updateSubLabel(dimModeItem, ROW_DIM_THEME, dimMode ? "On" : "Off");
    }

    function getMatchFormatLabel() {
        var model = getModel();
        if (model != null) {
            return RugbySettingsSupport.getMatchFormatLabelForValues(model.is7s, model.halfDuration);
        }
        return RugbySettingsSupport.getMatchFormatLabel(getActiveProfile());
    }

    function getConversionLabel() {
        var model = getModel();
        if (model != null) {
            return formatTime(model.conversionTime);
        }
        return RugbySettingsSupport.getConversionLabel(getActiveProfile(), self);
    }

    function getPenaltyLabel() {
        var model = getModel();
        if (model != null) {
            return formatTime(model.penaltyKickTime);
        }
        return RugbySettingsSupport.getPenaltyLabel(getActiveProfile(), self);
    }

    function getTeamLabelModeLabel() {
        var model = getModel();
        if (model != null) {
            return RugbyTeamIdentitySupport.getLabelModeDisplayName(model.teamLabelMode);
        }
        return RugbySettingsSupport.getTeamLabelModeLabel(getActiveProfile());
    }

    function getRowIndexForItemId(itemId) {
        if (itemId == :format_family) { return ROW_MATCH_FORMAT; }
        if (itemId == :conv_time) { return ROW_CONVERSION_TIMER; }
        if (itemId == :pen_time) { return ROW_PENALTY_TIMER; }
        if (itemId == :use_conv) { return ROW_USE_CONVERSION; }
        if (itemId == :use_pen) { return ROW_USE_PENALTY; }
        if (itemId == :team_labels) { return ROW_TEAM_LABELS; }
        if (itemId == :lock_start) { return ROW_LOCK_ON_START; }
        if (itemId == :dim_mode) { return ROW_DIM_THEME; }
        return 0;
    }

    function updateSubLabel(menuItem, rowIndex, text) {
        if (menuItem == null) {
            return;
        }
        menuItem.setSubLabel(text);
        updateItem(menuItem, rowIndex);
    }

    function formatTime(seconds) {
        if (seconds == null) { seconds = 0; }
        var mins = (seconds.toLong() / 60).toLong();
        var secs = (seconds.toLong() % 60).toLong();
        return mins.format("%02d") + ":" + secs.format("%02d");
    }
}
