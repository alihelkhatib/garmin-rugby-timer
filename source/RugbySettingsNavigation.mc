using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Timer;

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
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.model != null) {
            app.model.flushPendingCustomProfileSave();
        }
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

    function onSelect(item) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app == null || app.model == null) {
            return;
        }

        var isIdleOnlyRow = item.getId() == :profile || item.getId() == :format_family || item.getId() == :countdown_timer;
        if (isIdleOnlyRow && menu.isInGame()) {
            handleIdleOnlySelection();
            return;
        }

        if (item.getId() == :profile) {
            WatchUi.pushView(new MatchProfileMenu(), new MatchProfileDelegate(menu), WatchUi.SLIDE_UP);
        } else if (item.getId() == :format_family) {
            app.model.setFormatFamily(!(app.model.is7s == true));
            menu.refresh();
            WatchUi.requestUpdate();
        } else if (item.getId() == :countdown_timer) {
            var initialMinutes = app.model.countdownTimer / 60;
            initialMinutes = RugbySettingsSupport.clampMinutes(initialMinutes);
            WatchUi.pushView(new MinutesPicker(initialMinutes), new TimerPickerDelegate(menu), WatchUi.SLIDE_UP);
        } else if (item.getId() == :conv_time) {
            WatchUi.pushView(new ConversionAdjustMenu(), new ConversionAdjustDelegate(menu), WatchUi.SLIDE_UP);
        } else if (item.getId() == :pen_time) {
            WatchUi.pushView(new PenaltyAdjustMenu(), new PenaltyAdjustDelegate(menu), WatchUi.SLIDE_UP);
        } else if (item.getId() == :use_conv) {
            app.model.setConversionTimerEnabled(!(app.model.useConversionTimer == true));
            menu.refresh();
            WatchUi.requestUpdate();
        } else if (item.getId() == :use_pen) {
            app.model.setPenaltyTimerEnabled(!(app.model.usePenaltyTimer == true));
            menu.refresh();
            WatchUi.requestUpdate();
        } else if (item.getId() == :lock_start) {
            var lockStart = Storage.getValue(STORAGE_KEY_LOCK_ON_START);
            if (lockStart == null) { lockStart = false; }
            lockStart = !lockStart;
            Storage.setValue(STORAGE_KEY_LOCK_ON_START, lockStart);
            app.model.lockOnStart = lockStart;
            menu.refresh();
            WatchUi.requestUpdate();
        } else if (item.getId() == :dim_mode) {
            var dimMode = Storage.getValue(STORAGE_KEY_DIM_MODE);
            if (dimMode == null) { dimMode = false; }
            dimMode = !dimMode;
            Storage.setValue(STORAGE_KEY_DIM_MODE, dimMode);
            if (app.rugbyView != null) {
                app.rugbyView.dimMode = dimMode;
            }
            menu.refresh();
            WatchUi.requestUpdate();
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

/**
 * Menu for choosing one of the built-in match presets or the saved custom profile.
 */
class MatchProfileMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Match Preset"});
        addItem(new WatchUi.MenuItem("Rugby 7s", null, "7s", null));
        addItem(new WatchUi.MenuItem("Rugby 10s", null, "10s", null));
        addItem(new WatchUi.MenuItem("Rugby 15s", null, "15s", null));
        addItem(new WatchUi.MenuItem("U19", null, "u19", null));
        addItem(new WatchUi.MenuItem("Custom", null, "custom", null));
    }
}

/**
 * Applies the selected preset synchronously, then closes the picker.
 */
class MatchProfileDelegate extends WatchUi.Menu2InputDelegate {
    var menu;

    function initialize(settingsMenu) {
        Menu2InputDelegate.initialize();
        menu = settingsMenu;
    }

    function resolveProfileId(itemId) {
        return RugbySettingsSupport.resolveProfileId(itemId);
    }

    function applyProfileSelection(profileId) as Void {
        var app = Application.getApp() as RugbyTimerApp;
        if (app == null || app.model == null || profileId == null) {
            return;
        }
        if (app.model.gameState != STATE_IDLE) {
            if (app.rugbyView != null) {
                app.rugbyView.displaySpecialOverlayMessage("Idle only");
                WatchUi.requestUpdate();
            }
            return;
        }

        app.model.flushPendingCustomProfileSave();
        app.model.setMatchProfile(profileId);
        app.model.gameTime = 0;
        app.model.elapsedTime = 0;
        app.model.countdownSeconds = 0;
        app.model.countdownRemaining = app.model.countdownTimer;
        app.model.lastUpdate = System.getTimer();
        app.model.persistState();
        if (menu != null) {
            menu.refresh();
        }
        if (app.rugbyView != null) {
            app.rugbyView.displaySpecialOverlayMessage(RugbyMatchProfiles.getProfileLabel(profileId));
        }
        WatchUi.requestUpdate();
    }

    function onSelect(item) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app == null || app.model == null) {
            return;
        }

        var profileId = resolveProfileId(item.getId());
        if (profileId == null) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return;
        }
        applyProfileSelection(profileId);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
