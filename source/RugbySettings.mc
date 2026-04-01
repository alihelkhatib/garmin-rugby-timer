using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Graphics;

/**
 * The menu for the application settings.
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

    function initialize() {
        Menu2.initialize({:title=>"Rugby Settings"});
        var profile = getActiveProfile();
        var profileLabel = profile != null ? profile["label"] : null;
        var formatLabel = profile != null ? RugbyMatchProfiles.getFormatLabel(profile["is7s"]) : null;
        var halfLabel = profile != null ? formatTime(profile["halfDuration"]) : null;
        var conversionLabel = profile != null ? formatTime(profile["conversionTime"]) : null;
        var penaltyLabel = profile != null ? formatTime(profile["penaltyKickTime"]) : null;
        var useConvLabel = (profile != null && profile["useConversionTimer"] == true) ? "On" : "Off";
        var usePenLabel = (profile != null && profile["usePenaltyTimer"] == true) ? "On" : "Off";

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

        var lockStart = Storage.getValue("lockOnStart");
        if (lockStart == null) { lockStart = false; }
        lockStartItem = new WatchUi.MenuItem("Lock on Start", lockStart ? "On" : "Off", :lock_start, null);
        addItem(lockStartItem);

        var dimMode = Storage.getValue("dimMode");
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
 * Delegate for the settings menu.
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
            if (initialMinutes < 1) { initialMinutes = 1; }
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
            var lockStart = Storage.getValue("lockOnStart");
            if (lockStart == null) { lockStart = false; }
            lockStart = !lockStart;
            Storage.setValue("lockOnStart", lockStart);
            app.model.lockOnStart = lockStart;
            menu.refresh();
            WatchUi.requestUpdate();
        } else if (item.getId() == :dim_mode) {
            var dimMode = Storage.getValue("dimMode");
            if (dimMode == null) { dimMode = false; }
            dimMode = !dimMode;
            Storage.setValue("dimMode", dimMode);
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
        addItem(new WatchUi.MenuItem("Rugby 7s", null, :profile_7s, null));
        addItem(new WatchUi.MenuItem("Rugby 10s", null, :profile_10s, null));
        addItem(new WatchUi.MenuItem("Rugby 15s", null, :profile_15s, null));
        addItem(new WatchUi.MenuItem("U19", null, :profile_u19, null));
        addItem(new WatchUi.MenuItem("Custom", null, :profile_custom, null));
    }
}

class MatchProfileDelegate extends WatchUi.Menu2InputDelegate {
    var menu;

    function initialize(settingsMenu) {
        Menu2InputDelegate.initialize();
        menu = settingsMenu;
    }

    function resolveProfileId(itemId) {
        var idText = itemId != null ? itemId.toString() : "";
        if (itemId == :profile_7s || idText == "profile_7s" || idText == ":profile_7s") {
            return "7s";
        } else if (itemId == :profile_10s || idText == "profile_10s" || idText == ":profile_10s") {
            return "10s";
        } else if (itemId == :profile_15s || idText == "profile_15s" || idText == ":profile_15s") {
            return "15s";
        } else if (itemId == :profile_u19 || idText == "profile_u19" || idText == ":profile_u19") {
            return "u19";
        } else if (itemId == :profile_custom || idText == "profile_custom" || idText == ":profile_custom") {
            return "custom";
        }
        return null;
    }

    function onSelect(item) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app == null || app.model == null) {
            return;
        }

        if (app.model.gameState != STATE_IDLE) {
            if (app.rugbyView != null) {
                app.rugbyView.displaySpecialOverlayMessage("Idle only");
                WatchUi.requestUpdate();
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return;
        }

        var profileId = resolveProfileId(item.getId());
        if (profileId == null) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return;
        }
        app.model.setMatchProfile(profileId);
        if (menu != null) {
            menu.refresh();
        }
        if (profileId == "custom") {
            var customMenu = new RugbySettingsMenu();
            WatchUi.pushView(customMenu, new RugbySettingsMenuDelegate(customMenu, true), WatchUi.SLIDE_UP);
            return;
        }
        WatchUi.requestUpdate();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * A single-digit (0–9) picker factory.
 * Used to build the tens and units columns of MinutesPicker.
 */
class DigitPickerFactory extends WatchUi.PickerFactory {
    var mMin;
    var mMax;
    var mInitialIndex;

    function initialize(min, max, initialValue) {
        PickerFactory.initialize();
        mMin = min;
        mMax = max;
        mInitialIndex = initialValue - min;
        if (mInitialIndex < 0) { mInitialIndex = 0; }
        if (mInitialIndex > (mMax - mMin)) { mInitialIndex = mMax - mMin; }
    }

    function getDrawable(index, selected) {
        return new WatchUi.Text({
            :text  => (mMin + index).format("%d"),
            :font  => Graphics.FONT_NUMBER_HOT,
            :locX  => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY  => WatchUi.LAYOUT_VALIGN_CENTER,
            :color => selected ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY
        });
    }

    function getValue(index) {
        return mMin + index;
    }

    function getSize() {
        return mMax - mMin + 1;
    }

    function getInitialIndex() {
        return mInitialIndex;
    }
}

/**
 * Two-column minute picker (01–99 minutes).
 */
class MinutesPicker extends WatchUi.Picker {
    function initialize(currentMinutes) {
        if (currentMinutes < 1)  { currentMinutes = 1; }
        if (currentMinutes > 99) { currentMinutes = 99; }
        var tens = currentMinutes / 10;
        var units = currentMinutes % 10;
        Picker.initialize({
            :title => new WatchUi.Text({
                :text  => "Half Length (min)",
                :font  => Graphics.FONT_TINY,
                :locX  => WatchUi.LAYOUT_HALIGN_CENTER,
                :locY  => WatchUi.LAYOUT_VALIGN_CENTER,
                :color => Graphics.COLOR_WHITE
            }),
            :pattern => [
                new DigitPickerFactory(0, 9, tens),
                new DigitPickerFactory(0, 9, units)
            ]
        });
    }
}

class TimerPickerDelegate extends WatchUi.PickerDelegate {
    var menu;

    function initialize(settingsMenu) {
        PickerDelegate.initialize();
        menu = settingsMenu;
    }

    function onAccept(values) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.model != null) {
            var minutes = values[0] * 10 + values[1];
            if (minutes < 1) { minutes = 1; }
            app.model.setHalfDuration(minutes * 60);
            menu.refresh();
            WatchUi.requestUpdate();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onCancel() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

class ConversionAdjustMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Conversion Timer"});
        addItem(new WatchUi.MenuItem("30 sec", "00:30", :t30, null));
        addItem(new WatchUi.MenuItem("60 sec", "01:00", :t60, null));
        addItem(new WatchUi.MenuItem("90 sec", "01:30", :t90, null));
        addItem(new WatchUi.MenuItem("120 sec", "02:00", :t120, null));
    }
}

class ConversionAdjustDelegate extends WatchUi.Menu2InputDelegate {
    var menu;

    function initialize(settingsMenu) {
        Menu2InputDelegate.initialize();
        menu = settingsMenu;
    }

    function onSelect(item) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.model != null) {
            var val = 30;
            if (item.getId() == :t60) { val = 60; }
            else if (item.getId() == :t90) { val = 90; }
            else if (item.getId() == :t120) { val = 120; }
            app.model.setConversionTime(val);
            menu.refresh();
            WatchUi.requestUpdate();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class PenaltyAdjustMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Penalty Kick"});
        addItem(new WatchUi.MenuItem("30 sec", "00:30", :p30, null));
        addItem(new WatchUi.MenuItem("60 sec", "01:00", :p60, null));
        addItem(new WatchUi.MenuItem("90 sec", "01:30", :p90, null));
    }
}

class PenaltyAdjustDelegate extends WatchUi.Menu2InputDelegate {
    var menu;

    function initialize(settingsMenu) {
        Menu2InputDelegate.initialize();
        menu = settingsMenu;
    }

    function onSelect(item) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.model != null) {
            var val = 30;
            if (item.getId() == :p60) { val = 60; }
            else if (item.getId() == :p90) { val = 90; }
            app.model.setPenaltyKickTime(val);
            menu.refresh();
            WatchUi.requestUpdate();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
