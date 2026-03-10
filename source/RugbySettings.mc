using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Graphics;

/**
 * The menu for the application settings.
 */
class RugbySettingsMenu extends WatchUi.Menu2 {
    /**
     * Initializes the menu.
     */
    function initialize() {
        Menu2.initialize({:title=>"Rugby Settings"});
        
        var is7s = Storage.getValue("rugby7s");
        if (is7s == null) {
            is7s = false;
        }
        
        var gameType = is7s ? "Rugby 7s" : "Rugby 15s";
        addItem(new WatchUi.MenuItem("Game Type", gameType, :game_type, null));
        
        // Read per-type saved duration for the sub-label (FR-005)
        var typeKey = is7s ? "halfDuration7s" : "halfDuration15s";
        var savedDuration = Storage.getValue(typeKey);
        if (savedDuration == null) { savedDuration = Storage.getValue("countdownTimer"); }
        if (savedDuration == null) { savedDuration = is7s ? 420 : 2400; }
        var timerStr = formatTime(savedDuration);
        // Disable the Half Timer item while a match is in progress (FR-003, FR-008)
        var rugbyApp = Application.getApp();
        var inGame = (rugbyApp != null && rugbyApp has :model && rugbyApp.model != null && rugbyApp.model.gameState != 0);
        addItem(new WatchUi.MenuItem("Half Timer", timerStr, :countdown_timer, {:enabled => !inGame}));
        
        var conv7 = Storage.getValue("conversionTime7s");
        if (conv7 == null) { conv7 = 30; }
        addItem(new WatchUi.MenuItem("7s Conversion", formatTime(conv7), :conv7, null));
        
        var conv15 = Storage.getValue("conversionTime15s");
        if (conv15 == null) { conv15 = 90; }
        addItem(new WatchUi.MenuItem("15s Conversion", formatTime(conv15), :conv15, null));
        
        var penTime = Storage.getValue("penaltyKickTime");
        if (penTime == null) { penTime = 60; }
        addItem(new WatchUi.MenuItem("Penalty Kick", formatTime(penTime), :pen_time, null));
        
        var useConv = Storage.getValue("useConversionTimer");
        if (useConv == null) { useConv = true; }
        addItem(new WatchUi.MenuItem("Conversion Timer", useConv ? "On" : "Off", :use_conv, null));
        
        var usePen = Storage.getValue("usePenaltyTimer");
        if (usePen == null) { usePen = true; }
        addItem(new WatchUi.MenuItem("Penalty Timer", usePen ? "On" : "Off", :use_pen, null));

        var lockStart = Storage.getValue("lockOnStart");
        if (lockStart == null) { lockStart = false; }
        addItem(new WatchUi.MenuItem("Lock on Start", lockStart ? "On" : "Off", :lock_start, null));

        var dimMode = Storage.getValue("dimMode");
        if (dimMode == null) { dimMode = false; }
        addItem(new WatchUi.MenuItem("Dim Theme", dimMode ? "On" : "Off", :dim_mode, null));
        
        addItem(new WatchUi.MenuItem("Reset Scores", null, :reset, null));
    }
    
    /**
     * Formats a time in seconds into a MM:SS string.
     * @param seconds The time in seconds
     * @return The formatted time string
     */
    function formatTime(seconds) {
        var mins = (seconds.toLong() / 60).toLong();
        var secs = (seconds.toLong() % 60).toLong();
        return mins.format("%02d") + ":" + secs.format("%02d");
    }
}

/**
 * Delegate for the settings menu.
 */
class RugbySettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    /**
     * Initializes the delegate.
     */
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item) {
        if (item.getId() == :game_type) {
            var is7s = Storage.getValue("rugby7s");
            if (is7s == null) {
                is7s = false;
            }
            is7s = !is7s;
            Storage.setValue("rugby7s", is7s);
            
            // When toggling game type, load the saved duration for the new type
            var newTypeKey = is7s ? "halfDuration7s" : "halfDuration15s";
            var savedForNewType = Storage.getValue(newTypeKey);
            // If no per-type duration saved yet, write the type default as the starting value
            if (savedForNewType == null) {
                savedForNewType = is7s ? 420 : 2400;
                Storage.setValue(newTypeKey, savedForNewType);
            }
            
            // Update menu item
            var gameType = is7s ? "Rugby 7s" : "Rugby 15s";
            item.setSubLabel(gameType);
            WatchUi.requestUpdate();
        } else if (item.getId() == :countdown_timer) {
            // Open free-form minute picker pre-filled with the per-type saved duration
            var curIs7s = Storage.getValue("rugby7s");
            if (curIs7s == null) { curIs7s = false; }
            var curTypeKey = curIs7s ? "halfDuration7s" : "halfDuration15s";
            var currentSeconds = Storage.getValue(curTypeKey);
            if (currentSeconds == null) { currentSeconds = Storage.getValue("countdownTimer"); } // legacy fallback
            if (currentSeconds == null) { currentSeconds = curIs7s ? 420 : 2400; }
            var initialMinutes = currentSeconds / 60;
            if (initialMinutes < 1) { initialMinutes = 1; }
            WatchUi.pushView(new MinutesPicker(initialMinutes), new TimerPickerDelegate(item), WatchUi.SLIDE_UP);
        } else if (item.getId() == :conv7) {
            WatchUi.pushView(new ConversionAdjustMenu(true, item), new ConversionAdjustDelegate(true, item), WatchUi.SLIDE_UP);
        } else if (item.getId() == :conv15) {
            WatchUi.pushView(new ConversionAdjustMenu(false, item), new ConversionAdjustDelegate(false, item), WatchUi.SLIDE_UP);
        } else if (item.getId() == :pen_time) {
            WatchUi.pushView(new PenaltyAdjustMenu(item), new PenaltyAdjustDelegate(item), WatchUi.SLIDE_UP);
        } else if (item.getId() == :use_conv) {
            var useConv = Storage.getValue("useConversionTimer");
            if (useConv == null) { useConv = true; }
            useConv = !useConv;
            Storage.setValue("useConversionTimer", useConv);
            item.setSubLabel(useConv ? "On" : "Off");
            WatchUi.requestUpdate();
        } else if (item.getId() == :use_pen) {
            var usePen = Storage.getValue("usePenaltyTimer");
            if (usePen == null) { usePen = true; }
            usePen = !usePen;
            Storage.setValue("usePenaltyTimer", usePen);
            item.setSubLabel(usePen ? "On" : "Off");
            WatchUi.requestUpdate();
        } else if (item.getId() == :lock_start) {
            var lockStart = Storage.getValue("lockOnStart");
            if (lockStart == null) { lockStart = false; }
            lockStart = !lockStart;
            Storage.setValue("lockOnStart", lockStart);
            item.setSubLabel(lockStart ? "On" : "Off");
            WatchUi.requestUpdate();
        } else if (item.getId() == :dim_mode) {
            var dimMode = Storage.getValue("dimMode");
            if (dimMode == null) { dimMode = false; }
            dimMode = !dimMode;
            Storage.setValue("dimMode", dimMode);
            item.setSubLabel(dimMode ? "On" : "Off");
            var app = Application.getApp() as RugbyTimerApp;
            if (app != null && app.rugbyView != null) {
                app.rugbyView.dimMode = dimMode;
            }
            WatchUi.requestUpdate();
        } else if (item.getId() == :reset) {
            var app = Application.getApp() as RugbyTimerApp;
            if (app != null && app.model != null) {
                // Restore the per-type countdown timer to the model before resetting game state
                var resetIs7s = Storage.getValue("rugby7s");
                if (resetIs7s == null) { resetIs7s = false; }
                var resetTypeKey = resetIs7s ? "halfDuration7s" : "halfDuration15s";
                var savedTimer = Storage.getValue(resetTypeKey);
                if (savedTimer == null) { savedTimer = Storage.getValue("countdownTimer"); } // legacy fallback
                if (savedTimer != null) {
                    app.model.countdownTimer = savedTimer;
                }
                app.model.resetGame();
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    /**
     * This method is called when the back button is pressed.
     */
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
        if (mInitialIndex < 0)            { mInitialIndex = 0; }
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
 * Left column = tens digit, right column = units digit.
 * @param currentMinutes Starting scroll position in whole minutes.
 */
class MinutesPicker extends WatchUi.Picker {
    function initialize(currentMinutes) {
        if (currentMinutes < 1)  { currentMinutes = 1; }
        if (currentMinutes > 99) { currentMinutes = 99; }
        var tens  = currentMinutes / 10;
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
 * Picker delegate for the Settings → Half Timer flow.
 * Saves the chosen duration to Storage and updates the model if the game is idle.
 */
class TimerPickerDelegate extends WatchUi.PickerDelegate {
    var mParentItem;

    function initialize(parentItem) {
        PickerDelegate.initialize();
        mParentItem = parentItem;
    }

    function onAccept(values) {
        var minutes = values[0] * 10 + values[1];
        if (minutes < 1) { minutes = 1; }
        var seconds = minutes * 60;
        // Write to per-type key so each game type remembers its own duration independently
        var is7s = Storage.getValue("rugby7s");
        if (is7s == null) { is7s = false; }
        var typeKey = is7s ? "halfDuration7s" : "halfDuration15s";
        Storage.setValue(typeKey, seconds);
        if (mParentItem != null) {
            mParentItem.setSubLabel(minutes.format("%02d") + ":00");
        }
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.model != null && app.model.gameState == 0) {
            app.model.countdownTimer = seconds;
            app.model.countdownRemaining = seconds;
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
 * Menu for adjusting the conversion timer.
 */
class ConversionAdjustMenu extends WatchUi.Menu2 {
    /**
     * Initializes the menu.
     * @param is7s A boolean indicating if it is a 7s match
     * @param parent The parent menu item
     */
    function initialize(is7s, parent) {
        Menu2.initialize({:title=> is7s ? "7s Conversion" : "15s Conversion"});
        addItem(new WatchUi.MenuItem("30 sec", "00:30", :t30, null));
        addItem(new WatchUi.MenuItem("60 sec", "01:00", :t60, null));
        addItem(new WatchUi.MenuItem("90 sec", "01:30", :t90, null));
        if (!is7s) {
            addItem(new WatchUi.MenuItem("120 sec", "02:00", :t120, null));
        }
    }
}

/**
 * Delegate for the conversion adjust menu.
 */
class ConversionAdjustDelegate extends WatchUi.Menu2InputDelegate {
    var parentItem;
    var is7s;
    
    /**
     * Initializes the delegate.
     * @param isSevens A boolean indicating if it is a 7s match
     * @param parent The parent menu item
     */
    function initialize(isSevens, parent) {
        Menu2InputDelegate.initialize();
        parentItem = parent;
        is7s = isSevens;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item) {
        var val = 0;
        if (item.getId() == :t30) { val = 30; }
        else if (item.getId() == :t60) { val = 60; }
        else if (item.getId() == :t90) { val = 90; }
        else if (item.getId() == :t120) { val = 120; }
        
        if (is7s) {
            Storage.setValue("conversionTime7s", val);
        } else {
            Storage.setValue("conversionTime15s", val);
        }
        parentItem.setSubLabel(formatTime(val));
        
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.model != null) {
            if (is7s) {
                app.model.conversionTime7s = val;
            } else {
                app.model.conversionTime15s = val;
            }
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    /**
     * This method is called when the back button is pressed.
     */
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    /**
     * Formats a time in seconds into a MM:SS string.
     * @param seconds The time in seconds
     * @return The formatted time string
     */
    function formatTime(seconds) {
        var mins = (seconds.toLong() / 60).toLong();
        var secs = (seconds.toLong() % 60).toLong();
        return mins.format("%02d") + ":" + secs.format("%02d");
    }
}

/**
 * Menu for adjusting the penalty kick timer.
 */
class PenaltyAdjustMenu extends WatchUi.Menu2 {
    /**
     * Initializes the menu.
     * @param parent The parent menu item
     */
    function initialize(parent) {
        Menu2.initialize({:title=>"Penalty Kick"});
        addItem(new WatchUi.MenuItem("30 sec", "00:30", :p30, null));
        addItem(new WatchUi.MenuItem("60 sec", "01:00", :p60, null));
        addItem(new WatchUi.MenuItem("90 sec", "01:30", :p90, null));
    }
}

/**
 * Delegate for the penalty adjust menu.
 */
class PenaltyAdjustDelegate extends WatchUi.Menu2InputDelegate {
    var parentItem;

    /**
     * Initializes the delegate.
     * @param parent The parent menu item
     */
    function initialize(parent) {
        Menu2InputDelegate.initialize();
        parentItem = parent;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item) {
        var val = 0;
        if (item.getId() == :p30) { val = 30; }
        else if (item.getId() == :p60) { val = 60; }
        else if (item.getId() == :p90) { val = 90; }
        
        Storage.setValue("penaltyKickTime", val);
        parentItem.setSubLabel(formatTime(val));
        
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.model != null) {
            app.model.penaltyKickTime = val;
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    /**
     * This method is called when the back button is pressed.
     */
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    /**
     * Formats a time in seconds into a MM:SS string.
     * @param seconds The time in seconds
     * @return The formatted time string
     */
    function formatTime(seconds) {
        var mins = (seconds.toLong() / 60).toLong();
        var secs = (seconds.toLong() % 60).toLong();
        return mins.format("%02d") + ":" + secs.format("%02d");
    }
}