using Toybox.WatchUi;

class RugbyTimerDelegate extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onMenu() {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new MainMenuDelegate(view), WatchUi.SLIDE_UP);
        return true;
    }

    function onSelect() {
        // Start/pause game with select button
        if (view.gameState == STATE_IDLE) {
            view.startGame();
        } else if (view.gameState == STATE_PLAYING) {
            view.pauseGame();
        } else if (view.gameState == STATE_HALFTIME) {
            view.startSecondHalf();
        }
        return true;
    }

    function onBack() {
        // Show confirmation menu before exiting
        if (view.gameState != STATE_IDLE) {
            var menu = new WatchUi.Menu2({:title=>"Exit?"});
            menu.addItem(new WatchUi.MenuItem("Resume", null, :resume, null));
            menu.addItem(new WatchUi.MenuItem("End Game", null, :end, null));
            menu.addItem(new WatchUi.MenuItem("Reset Game", null, :reset, null));
            menu.addItem(new WatchUi.MenuItem("Exit App", null, :exit, null));
            WatchUi.pushView(menu, new ExitMenuDelegate(view), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }

    function onNextPage() {
        // Quick score - home try
        view.recordTry(true);
        return true;
    }

    function onPreviousPage() {
        // Quick score - away try
        view.recordTry(false);
        return true;
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view;

    function initialize(v) {
        Menu2InputDelegate.initialize();
        view = v;
    }

    function onSelect(item) {
        if (item.getId() == :home_try) {
            view.recordTry(true);
        } else if (item.getId() == :away_try) {
            view.recordTry(false);
        } else if (item.getId() == :home_conv) {
            view.recordConversion(true);
        } else if (item.getId() == :away_conv) {
            view.recordConversion(false);
        } else if (item.getId() == :home_pen) {
            view.recordPenalty(true);
        } else if (item.getId() == :away_pen) {
            view.recordPenalty(false);
        } else if (item.getId() == :home_drop) {
            view.recordDropGoal(true);
        } else if (item.getId() == :away_drop) {
            view.recordDropGoal(false);
        } else if (item.getId() == :start_half2) {
            view.startSecondHalf();
        } else if (item.getId() == :end_game) {
            view.endGame();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class ExitMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view;

    function initialize(v) {
        Menu2InputDelegate.initialize();
        view = v;
    }

    function onSelect(item) {
        if (item.getId() == :resume) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (item.getId() == :end) {
            view.endGame();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (item.getId() == :exit) {
            view.stopRecording();
            System.exit();
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}