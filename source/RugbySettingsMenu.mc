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
    const ROW_HALFTIME_BREAK = 2;
    const ROW_PENALTY_TIMER = 3;
    const ROW_USE_CONVERSION = 4;
    const ROW_USE_PENALTY = 5;
    const ROW_TEAM_LABELS = 6;
    const ROW_LOCK_ON_START = 7;
    const ROW_DIM_THEME = 8;

    var formatItem;
    var conversionItem;
    var penaltyItem;
    var halftimeItem;
    var useConvItem;
    var usePenItem;
    var teamLabelsItem;
    var lockStartItem;
    var dimModeItem;

    function initialize() {
        Menu2.initialize({:title=>"Rugby Settings"});
        var displayState = getDisplayState();

        formatItem = new WatchUi.MenuItem("Match Format", displayState.matchFormatLabel, :format_family, null);
        addItem(formatItem);

        conversionItem = new WatchUi.MenuItem("Conversion Timer", displayState.conversionLabel, :conv_time, null);
        addItem(conversionItem);

        halftimeItem = new WatchUi.MenuItem("Halftime Break", displayState.halftimeBreakLabel, :half_break, null);
        addItem(halftimeItem);

        penaltyItem = new WatchUi.MenuItem("Penalty Kick", displayState.penaltyLabel, :pen_time, null);
        addItem(penaltyItem);

        useConvItem = new WatchUi.MenuItem("Conversion Overlay", displayState.useConversionLabel, :use_conv, null);
        addItem(useConvItem);

        usePenItem = new WatchUi.MenuItem("Penalty Overlay", displayState.usePenaltyLabel, :use_pen, null);
        addItem(usePenItem);

        teamLabelsItem = new WatchUi.MenuItem("Team Labels", displayState.teamLabelsLabel, :team_labels, null);
        addItem(teamLabelsItem);

        lockStartItem = new WatchUi.MenuItem("Lock on Start", displayState.lockOnStartLabel, :lock_start, null);
        addItem(lockStartItem);

        dimModeItem = new WatchUi.MenuItem("Dim Theme", displayState.dimThemeLabel, :dim_mode, null);
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
        var displayState = getDisplayState();
        updateSubLabel(formatItem, ROW_MATCH_FORMAT, displayState.matchFormatLabel);
        updateSubLabel(conversionItem, ROW_CONVERSION_TIMER, displayState.conversionLabel);
        updateSubLabel(halftimeItem, ROW_HALFTIME_BREAK, displayState.halftimeBreakLabel);
        updateSubLabel(penaltyItem, ROW_PENALTY_TIMER, displayState.penaltyLabel);
        updateSubLabel(useConvItem, ROW_USE_CONVERSION, displayState.useConversionLabel);
        updateSubLabel(usePenItem, ROW_USE_PENALTY, displayState.usePenaltyLabel);
        updateSubLabel(teamLabelsItem, ROW_TEAM_LABELS, displayState.teamLabelsLabel);
        updateSubLabel(lockStartItem, ROW_LOCK_ON_START, displayState.lockOnStartLabel);
        updateSubLabel(dimModeItem, ROW_DIM_THEME, displayState.dimThemeLabel);
    }

    function getDisplayState() {
        var lockStart = Storage.getValue(STORAGE_KEY_LOCK_ON_START);
        var dimMode = Storage.getValue(STORAGE_KEY_DIM_MODE);
        if (lockStart == null) { lockStart = false; }
        if (dimMode == null) { dimMode = false; }
        return RugbySettingsSupport.buildDisplayState(getModel(), getActiveProfile(), lockStart, dimMode);
    }

    function getRowIndexForItemId(itemId) {
        if (itemId == :format_family) { return ROW_MATCH_FORMAT; }
        if (itemId == :conv_time) { return ROW_CONVERSION_TIMER; }
        if (itemId == :half_break) { return ROW_HALFTIME_BREAK; }
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
        return RugbySettingsSupport.formatTime(seconds);
    }
}
