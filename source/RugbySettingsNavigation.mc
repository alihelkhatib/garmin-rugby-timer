using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Graphics;

/**
 * Settings navigation host and delegate implementations.
 *
 * Purpose: own the WatchUi-specific flow between the settings root menu,
 * submenus, and picker delegates while leaving pure rules in helpers.
 */
class RugbySettingsHostView extends WatchUi.View {
    var launchedMenu;

    function initialize() {
        View.initialize();
        launchedMenu = false;
    }

    function onShow() as Void {
        if (!launchedMenu) {
            launchedMenu = true;
            var menu = new RugbySettingsMenu();
            WatchUi.pushView(menu, new RugbySettingsMenuDelegate(menu, true), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onUpdate(dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
    }
}

/**
 * Lightweight delegate for dismissing the settings host wrapper.
 */
class RugbySettingsHostDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

class RugbySettingsNavigationSupport {
    static function replaceRootMenuAtRow(rowIndex) {
        var refreshedMenu = new RugbySettingsMenu();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(refreshedMenu, new RugbySettingsMenuDelegate(refreshedMenu, true), WatchUi.SLIDE_IMMEDIATE);
        refreshedMenu.setFocus(rowIndex);
        WatchUi.requestUpdate();
    }

    static function returnToRefreshedRootMenu(rowIndex) {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        RugbySettingsNavigationSupport.replaceRootMenuAtRow(rowIndex);
    }
}

/**
 * Delegate for settings navigation and side effects.
 *
 * Responsibility boundary:
 * route row selections into model/storage updates or submenus without
 * rebuilding menu structure logic here.
 */
class RugbySettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var menu;
    var embeddedInApp;

    function initialize(settingsMenu, embedded) {
        Menu2InputDelegate.initialize();
        menu = settingsMenu;
        embeddedInApp = embedded == true;
    }

    function closeSettingsRoot() {
        if (embeddedInApp) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function handleIdleOnlySelection() {
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.rugbyView != null) {
            app.rugbyView.displaySpecialOverlayMessage("Idle only");
            WatchUi.requestUpdate();
        }
    }

    function rebuildSettingsRoot() {
        rebuildSettingsRootAtRow(0);
    }

    function rebuildSettingsRootAtRow(rowIndex) {
        RugbySettingsNavigationSupport.replaceRootMenuAtRow(rowIndex);
    }

    function onSelect(item) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app == null || app.model == null) {
            return;
        }

        var isIdleOnlyRow = item.getId() == :format_family || item.getId() == :team_labels;
        if (isIdleOnlyRow && menu.isInGame()) {
            handleIdleOnlySelection();
            return;
        }

        if (item.getId() == :format_family) {
            WatchUi.pushView(
                new MatchFormatMenu(app.model.matchProfileId),
                new MatchFormatDelegate(menu),
                WatchUi.SLIDE_UP
            );
        } else if (item.getId() == :conv_time) {
            WatchUi.pushView(new ConversionAdjustMenu(), new ConversionAdjustDelegate(menu), WatchUi.SLIDE_UP);
        } else if (item.getId() == :pen_time) {
            WatchUi.pushView(new PenaltyAdjustMenu(), new PenaltyAdjustDelegate(menu), WatchUi.SLIDE_UP);
        } else if (item.getId() == :use_conv) {
            app.model.setConversionTimerEnabled(!(app.model.useConversionTimer == true));
            rebuildSettingsRootAtRow(menu.getRowIndexForItemId(item.getId()));
        } else if (item.getId() == :use_pen) {
            app.model.setPenaltyTimerEnabled(!(app.model.usePenaltyTimer == true));
            rebuildSettingsRootAtRow(menu.getRowIndexForItemId(item.getId()));
        } else if (item.getId() == :team_labels) {
            WatchUi.pushView(
                new TeamLabelModeMenu(app.model.teamLabelMode),
                new TeamLabelModeDelegate(menu),
                WatchUi.SLIDE_UP
            );
        } else if (item.getId() == :lock_start) {
            var lockStart = Storage.getValue(STORAGE_KEY_LOCK_ON_START);
            if (lockStart == null) { lockStart = false; }
            lockStart = !lockStart;
            RugbyStorageSupport.setValue(STORAGE_KEY_LOCK_ON_START, lockStart);
            app.model.lockOnStart = lockStart;
            rebuildSettingsRootAtRow(menu.getRowIndexForItemId(item.getId()));
        } else if (item.getId() == :dim_mode) {
            var dimMode = Storage.getValue(STORAGE_KEY_DIM_MODE);
            if (dimMode == null) { dimMode = false; }
            dimMode = !dimMode;
            RugbyStorageSupport.setValue(STORAGE_KEY_DIM_MODE, dimMode);
            if (app.rugbyView != null) {
                app.rugbyView.dimMode = dimMode;
            }
            rebuildSettingsRootAtRow(menu.getRowIndexForItemId(item.getId()));
        } else if (item.getId() == :reset) {
            app.model.setMatchProfile(app.model.matchProfileId);
            app.model.resetGame();
            closeSettingsRoot();
        }
    }

    function onBack() {
        closeSettingsRoot();
    }
}

class TeamLabelModeMenu extends WatchUi.Menu2 {
    function initialize(currentMode) {
        Menu2.initialize({:title=>"Team Labels"});
        TeamLabelModeMenu.addModeItem(self, currentMode, "Home / Away", TEAM_LABEL_MODE_HOME_AWAY);
        TeamLabelModeMenu.addModeItem(self, currentMode, "Team A / Team B", TEAM_LABEL_MODE_TEAM_A_B);
        TeamLabelModeMenu.addModeItem(self, currentMode, "Light / Dark", TEAM_LABEL_MODE_LIGHT_DARK);
        TeamLabelModeMenu.addModeItem(self, currentMode, "Red / Blue", TEAM_LABEL_MODE_RED_BLUE);
        TeamLabelModeMenu.addModeItem(self, currentMode, "1st XV / 2nd XV", TEAM_LABEL_MODE_FIRST_SECOND_XV);
        TeamLabelModeMenu.addModeItem(self, currentMode, "Varsity / JV", TEAM_LABEL_MODE_VARSITY_JV);
        TeamLabelModeMenu.addModeItem(self, currentMode, "Sharks / Blues", TEAM_LABEL_MODE_SHARKS_BLUES);
        TeamLabelModeMenu.addModeItem(self, currentMode, "A / B", TEAM_LABEL_MODE_A_B);
    }

    static function addModeItem(menu, currentMode, title, mode) {
        var subtitle = null;
        if (RugbyTeamIdentitySupport.normalizeLabelMode(currentMode) == mode) {
            subtitle = "Current";
        }
        menu.addItem(new WatchUi.MenuItem(title, subtitle, mode, null));
    }
}

class TeamLabelModeDelegate extends WatchUi.Menu2InputDelegate {
    var settingsMenu;

    function initialize(rootMenu) {
        Menu2InputDelegate.initialize();
        settingsMenu = rootMenu;
    }

    function onSelect(item) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app == null || app.model == null) {
            return;
        }
        var selectedMode = item.getId();
        var resolvedMode = null;
        if (selectedMode != null) {
            resolvedMode = RugbyTeamIdentitySupport.normalizeLabelMode(selectedMode.toString());
            if (resolvedMode == TEAM_LABEL_MODE_HOME_AWAY && selectedMode.toString() != TEAM_LABEL_MODE_HOME_AWAY) {
                resolvedMode = RugbySettingsSupport.resolveTeamLabelMode(selectedMode);
            }
            if (resolvedMode == TEAM_LABEL_MODE_HOME_AWAY && selectedMode.toString() != TEAM_LABEL_MODE_HOME_AWAY && selectedMode.toString() != "Home / Away") {
                resolvedMode = RugbySettingsSupport.resolveTeamLabelModeFromText(selectedMode.toString());
            }
        }
        if (resolvedMode == null || resolvedMode == TEAM_LABEL_MODE_HOME_AWAY) {
            try {
                resolvedMode = RugbySettingsSupport.resolveTeamLabelModeFromText(item.getLabel().toString());
            } catch (ex) {
            }
        }
        app.model.setTeamLabelMode(resolvedMode);
        RugbySettingsNavigationSupport.returnToRefreshedRootMenu(5);
    }
}

class MatchFormatMenu extends WatchUi.Menu2 {
    function initialize(currentProfileId) {
        Menu2.initialize({:title=>"Match Format"});
        var app = Application.getApp() as RugbyTimerApp;
        var currentFormatLabel = null;
        if (app != null && app.model != null) {
            currentFormatLabel = RugbySettingsSupport.getMatchFormatLabelForValues(app.model.is7s, app.model.halfDuration);
        } else {
            currentFormatLabel = RugbySettingsSupport.getMatchFormatLabel(RugbyMatchProfiles.getProfile(currentProfileId));
        }
        MatchFormatMenu.addFormatItem(self, currentFormatLabel, "7s");
        MatchFormatMenu.addFormatItem(self, currentFormatLabel, "10s");
        MatchFormatMenu.addFormatItem(self, currentFormatLabel, "15s");
        MatchFormatMenu.addFormatItem(self, currentFormatLabel, "U19s");
    }

    static function addFormatItem(menu, currentFormatLabel, title) {
        menu.addItem(new WatchUi.MenuItem(title, currentFormatLabel == title ? "Current" : null, title, null));
    }
}

class MatchFormatDelegate extends WatchUi.Menu2InputDelegate {
    var settingsMenu;

    function initialize(rootMenu) {
        Menu2InputDelegate.initialize();
        settingsMenu = rootMenu;
    }

    function onSelect(item) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app == null || app.model == null) {
            return;
        }
        var selectedFormat = item.getId() != null ? item.getId().toString() : null;
        var profileId = RugbySettingsSupport.resolveMatchFormatIdFromText(selectedFormat);
        if (profileId == null) {
            try {
                profileId = RugbySettingsSupport.resolveMatchFormatIdFromText(item.getLabel().toString());
            } catch (ex) {
            }
        }
        if (profileId == null) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return;
        }
        app.model.setMatchProfile(profileId);
        RugbySettingsNavigationSupport.returnToRefreshedRootMenu(0);
    }
}
