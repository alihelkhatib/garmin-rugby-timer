using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Graphics;

/**
 * Picker widgets used by the settings flow.
 *
 * Purpose: hold the reusable minute-digit picker factories and delegates so
 * picker-specific UI code stays out of the settings navigation file.
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
        currentMinutes = RugbySettingsSupport.clampMinutes(currentMinutes);
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

/**
 * Applies minute-picker selections back into the model.
 */
class TimerPickerDelegate extends WatchUi.PickerDelegate {
    var menu;

    function initialize(settingsMenu) {
        PickerDelegate.initialize();
        menu = settingsMenu;
    }

    function onAccept(values) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.model != null) {
            var minutes = RugbySettingsSupport.getMinutesFromDigits(values);
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

/**
 * Menu for choosing the conversion overlay duration.
 */
class ConversionAdjustMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Conversion Timer"});
        addItem(new WatchUi.MenuItem("30 sec", "00:30", "t30", null));
        addItem(new WatchUi.MenuItem("60 sec", "01:00", "t60", null));
        addItem(new WatchUi.MenuItem("90 sec", "01:30", "t90", null));
        addItem(new WatchUi.MenuItem("120 sec", "02:00", "t120", null));
    }
}

/**
 * Delegate for conversion overlay duration changes.
 */
class ConversionAdjustDelegate extends WatchUi.Menu2InputDelegate {
    var settingsMenu;

    function initialize(settingsMenu) {
        Menu2InputDelegate.initialize();
        self.settingsMenu = settingsMenu;
    }

    function onSelect(item) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.model != null) {
            var val = RugbySettingsSupport.getConversionSelectionSeconds(item.getId());
            if (val == 30) {
                try {
                    val = RugbySettingsSupport.getConversionSelectionSeconds(item.getLabel().toString().find("120") != null ? "t120" : item.getLabel().toString().find("90") != null ? "t90" : item.getLabel().toString().find("60") != null ? "t60" : "t30");
                } catch (ex) {
                }
            }
            app.model.setConversionTime(val);
        }
        RugbySettingsNavigationSupport.returnToRefreshedRootMenu(1);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Menu for choosing the halftime-break duration.
 */
class HalftimeBreakAdjustMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Halftime Break"});
        addItem(new WatchUi.MenuItem("30 sec", "00:30", "h30", null));
        addItem(new WatchUi.MenuItem("60 sec", "01:00", "h60", null));
        addItem(new WatchUi.MenuItem("2 min", "02:00", "h120", null));
        addItem(new WatchUi.MenuItem("5 min", "05:00", "h300", null));
        addItem(new WatchUi.MenuItem("10 min", "10:00", "h600", null));
    }
}

class HalftimeBreakAdjustDelegate extends WatchUi.Menu2InputDelegate {
    var settingsMenu;

    function initialize(settingsMenu) {
        Menu2InputDelegate.initialize();
        self.settingsMenu = settingsMenu;
    }

    function onSelect(item) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.model != null) {
            var val = RugbySettingsSupport.getHalftimeBreakSelectionSeconds(item.getId());
            if (val == 30) {
                try {
                    var label = item.getLabel().toString();
                    val = RugbySettingsSupport.getHalftimeBreakSelectionSeconds(
                        label.find("10") != null ? "h600" : label.find("5") != null ? "h300" : label.find("2") != null ? "h120" : label.find("60") != null ? "h60" : "h30"
                    );
                } catch (ex) {
                }
            }
            app.model.setKickoffTime(val);
        }
        RugbySettingsNavigationSupport.returnToRefreshedRootMenu(2);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Menu for choosing the penalty-kick overlay duration.
 */
class PenaltyAdjustMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Penalty Kick"});
        addItem(new WatchUi.MenuItem("30 sec", "00:30", "p30", null));
        addItem(new WatchUi.MenuItem("60 sec", "01:00", "p60", null));
        addItem(new WatchUi.MenuItem("90 sec", "01:30", "p90", null));
    }
}

/**
 * Delegate for penalty overlay duration changes.
 */
class PenaltyAdjustDelegate extends WatchUi.Menu2InputDelegate {
    var settingsMenu;

    function initialize(settingsMenu) {
        Menu2InputDelegate.initialize();
        self.settingsMenu = settingsMenu;
    }

    function onSelect(item) {
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.model != null) {
            var val = RugbySettingsSupport.getPenaltySelectionSeconds(item.getId());
            if (val == 30) {
                try {
                    val = RugbySettingsSupport.getPenaltySelectionSeconds(item.getLabel().toString().find("90") != null ? "p90" : item.getLabel().toString().find("60") != null ? "p60" : "p30");
                } catch (ex) {
                }
            }
            app.model.setPenaltyKickTime(val);
        }
        RugbySettingsNavigationSupport.returnToRefreshedRootMenu(2);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
