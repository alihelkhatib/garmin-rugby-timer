using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Application.Storage;

class RugbySettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Rugby Settings"});
        
        var is7s = Storage.getValue("rugby7s");
        if (is7s == null) {
            is7s = false;
        }
        
        var gameType = is7s ? "Rugby 7s" : "Rugby 15s";
        addItem(new WatchUi.MenuItem("Game Type", gameType, :game_type, null));
        
        // Add countdown timer setting
        var countdownTimer = Storage.getValue("countdownTimer");
        if (countdownTimer == null) {
            countdownTimer = is7s ? 420 : 2400;  // Default based on game type
        }
        var timerStr = formatTime(countdownTimer);
        addItem(new WatchUi.MenuItem("Half Timer", timerStr, :countdown_timer, null));
        
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
    
    function formatTime(seconds) {
        var mins = (seconds.toLong() / 60).toLong();
        var secs = (seconds.toLong() % 60).toLong();
        return mins.format("%02d") + ":" + secs.format("%02d");
    }
}

class RugbySettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        if (item.getId() == :game_type) {
            var is7s = Storage.getValue("rugby7s");
            if (is7s == null) {
                is7s = false;
            }
            is7s = !is7s;
            Storage.setValue("rugby7s", is7s);
            
            // Update default countdown timer when switching game types
            var defaultTimer = is7s ? 420 : 2400;
            Storage.setValue("countdownTimer", defaultTimer);
            
            // Update menu item
            var gameType = is7s ? "Rugby 7s" : "Rugby 15s";
            item.setSubLabel(gameType);
            WatchUi.requestUpdate();
        } else if (item.getId() == :countdown_timer) {
            // Open timer adjustment menu
            WatchUi.pushView(new TimerAdjustMenu(), new TimerAdjustMenuDelegate(item), WatchUi.SLIDE_UP);
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
            if (app != null && app.rugbyView != null) {
                // Reset countdown timer to stored value
                var countdownTimer = Storage.getValue("countdownTimer");
                if (countdownTimer != null) {
                    app.rugbyView.countdownTimer = countdownTimer;
                }
                app.rugbyView.resetGame();
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class TimerAdjustMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Half Timer"});
        
        addItem(new WatchUi.MenuItem("5 minutes", "5:00", :timer_5, null));
        addItem(new WatchUi.MenuItem("7 minutes", "7:00", :timer_7, null));
        addItem(new WatchUi.MenuItem("10 minutes", "10:00", :timer_10, null));
        addItem(new WatchUi.MenuItem("15 minutes", "15:00", :timer_15, null));
        addItem(new WatchUi.MenuItem("20 minutes", "20:00", :timer_20, null));
        addItem(new WatchUi.MenuItem("30 minutes", "30:00", :timer_30, null));
        addItem(new WatchUi.MenuItem("40 minutes", "40:00", :timer_40, null));
        addItem(new WatchUi.MenuItem("45 minutes", "45:00", :timer_45, null));
    }
}

class TimerAdjustMenuDelegate extends WatchUi.Menu2InputDelegate {
    var parentItem;
    
    function initialize(parent) {
        Menu2InputDelegate.initialize();
        parentItem = parent;
    }

    function onSelect(item) {
        var timerValue = 0;
        
        if (item.getId() == :timer_5) {
            timerValue = 300;
        } else if (item.getId() == :timer_7) {
            timerValue = 420;
        } else if (item.getId() == :timer_10) {
            timerValue = 600;
        } else if (item.getId() == :timer_15) {
            timerValue = 900;
        } else if (item.getId() == :timer_20) {
            timerValue = 1200;
        } else if (item.getId() == :timer_30) {
            timerValue = 1800;
        } else if (item.getId() == :timer_40) {
            timerValue = 2400;
        } else if (item.getId() == :timer_45) {
            timerValue = 2700;
        }
        
        Storage.setValue("countdownTimer", timerValue);
        
        // Update parent menu item
        var timeStr = formatTime(timerValue);
        parentItem.setSubLabel(timeStr);
        
        // Update the view's countdown timer if idle
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.rugbyView != null && app.rugbyView.gameState == 0) {  // STATE_IDLE
            app.rugbyView.countdownTimer = timerValue;
            app.rugbyView.countdownRemaining = timerValue;
            WatchUi.requestUpdate();
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    function formatTime(seconds) {
        var mins = (seconds.toLong() / 60).toLong();
        var secs = (seconds.toLong() % 60).toLong();
        return mins.format("%02d") + ":" + secs.format("%02d");
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class ConversionAdjustMenu extends WatchUi.Menu2 {
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

class ConversionAdjustDelegate extends WatchUi.Menu2InputDelegate {
    var parentItem;
    var is7s;
    
    function initialize(isSevens, parent) {
        Menu2InputDelegate.initialize();
        parentItem = parent;
        is7s = isSevens;
    }

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
        if (app != null && app.rugbyView != null) {
            if (is7s) {
                app.rugbyView.conversionTime7s = val;
            } else {
                app.rugbyView.conversionTime15s = val;
            }
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    function formatTime(seconds) {
        var mins = (seconds.toLong() / 60).toLong();
        var secs = (seconds.toLong() % 60).toLong();
        return mins.format("%02d") + ":" + secs.format("%02d");
    }
}

class PenaltyAdjustMenu extends WatchUi.Menu2 {
    function initialize(parent) {
        Menu2.initialize({:title=>"Penalty Kick"});
        addItem(new WatchUi.MenuItem("30 sec", "00:30", :p30, null));
        addItem(new WatchUi.MenuItem("60 sec", "01:00", :p60, null));
        addItem(new WatchUi.MenuItem("90 sec", "01:30", :p90, null));
    }
}

class PenaltyAdjustDelegate extends WatchUi.Menu2InputDelegate {
    var parentItem;
    function initialize(parent) {
        Menu2InputDelegate.initialize();
        parentItem = parent;
    }

    function onSelect(item) {
        var val = 0;
        if (item.getId() == :p30) { val = 30; }
        else if (item.getId() == :p60) { val = 60; }
        else if (item.getId() == :p90) { val = 90; }
        
        Storage.setValue("penaltyKickTime", val);
        parentItem.setSubLabel(formatTime(val));
        
        var app = Application.getApp() as RugbyTimerApp;
        if (app != null && app.rugbyView != null) {
            app.rugbyView.penaltyKickTime = val;
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    function formatTime(seconds) {
        var mins = (seconds.toLong() / 60).toLong();
        var secs = (seconds.toLong() % 60).toLong();
        return mins.format("%02d") + ":" + secs.format("%02d");
    }
}
