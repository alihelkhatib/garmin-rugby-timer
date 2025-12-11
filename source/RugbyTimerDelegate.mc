using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;

class RugbyTimerDelegate extends WatchUi.BehaviorDelegate {
    var model;

    function initialize(m) {
        BehaviorDelegate.initialize();
        model = m;
    }

    function onMenu() {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new MainMenuDelegate(model), WatchUi.SLIDE_UP);
        return true;
    }

    function onSelect() {
        if (Application.getApp().rugbyView.isLocked) {
            return true;
        }
        // Start/pause/resume game with select button
        if (model.gameState == STATE_IDLE) {
            model.startGame();
        } else if (model.gameState == STATE_PLAYING || model.gameState == STATE_CONVERSION || model.gameState == STATE_PENALTY || model.gameState == STATE_KICKOFF) {
            model.pauseClock();
        } else if (model.gameState == STATE_PAUSED) {
            model.resumeClock();
        } else if (model.gameState == STATE_HALFTIME) {
            model.startSecondHalf();
        }
        return true;
    }

    function onBack() {
        if (Application.getApp().rugbyView.isLocked) {
            return true;
        }
        // Show confirmation menu before exiting
        if (model.gameState != STATE_IDLE) {
            var menu = new WatchUi.Menu2({:title=>"Exit?"});
            menu.addItem(new WatchUi.MenuItem("Resume", null, :resume, null));
            menu.addItem(new WatchUi.MenuItem("End Game", null, :end, null));
            menu.addItem(new WatchUi.MenuItem("Reset Game", null, :reset, null));
            menu.addItem(new WatchUi.MenuItem("Save Game", null, :save_game, null));
            menu.addItem(new WatchUi.MenuItem("Event Log", null, :view_log, null));
            menu.addItem(new WatchUi.MenuItem("Exit App", null, :exit, null));
            WatchUi.pushView(menu, new ExitMenuDelegate(model), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }

    function onNextPage() {
        var view = Application.getApp().rugbyView;
        if (view.isLocked || !view.isActionAllowed()) {
            return true;
        }
        if (view.isSpecialOverlayActive() && model.gameState == STATE_CONVERSION) {
            view.closeSpecialTimerScreen();
            model.handleConversionMiss();
            return true;
        }
        if (view.isSpecialOverlayActive()) {
            view.closeSpecialTimerScreen();
        }
        if (model.gameState == STATE_CONVERSION) {
            model.handleConversionMiss();
        } else {
            view.showCardDialog();
        }
        return true;
    }

    function onPreviousPage() {
        var view = Application.getApp().rugbyView;
        if (view.isLocked || !view.isActionAllowed()) {
            return true;
        }
        if (view.isSpecialOverlayActive() && model.gameState == STATE_CONVERSION) {
            view.closeSpecialTimerScreen();
            model.handleConversionSuccess();
            return true;
        }
        if (view.isSpecialOverlayActive()) {
            view.closeSpecialTimerScreen();
        }
        if (model.gameState == STATE_CONVERSION) {
            model.handleConversionSuccess();
        } else if (model.gameState == STATE_KICKOFF) {
            model.cancelKickoff();
        }
        else {
            view.showScoreDialog();
        }
        return true;
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    var model;

    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    function onSelect(item) {
        var view = Application.getApp().rugbyView;
        if (item.getId() == :record_score) {
            view.showScoreDialog();
        } else if (item.getId() == :record_card) {
            view.showCardDialog();
        } else if (item.getId() == :pause_clock) {
            if (model.gameState == STATE_PAUSED) {
                model.resumeClock();
            } else {
                model.pauseClock();
            }
        } else if (item.getId() == :start_half2) {
            model.startSecondHalf();
        } else if (item.getId() == :end_game) {
            model.endGame();
        } else if (item.getId() == :undo_last) {
            model.undoLastEvent();
        } else if (item.getId() == :adjust_score) {
            WatchUi.pushView(new AdjustScoreMenu(), new AdjustScoreDelegate(model), WatchUi.SLIDE_UP);
            return;
        } else if (item.getId() == :toggle_lock) {
            view.toggleLock();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class AdjustScoreMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Adjust Score"});
        addItem(new WatchUi.MenuItem("Home +1", null, :home_plus, null));
        addItem(new WatchUi.MenuItem("Home -1", null, :home_minus, null));
        addItem(new WatchUi.MenuItem("Away +1", null, :away_plus, null));
        addItem(new WatchUi.MenuItem("Away -1", null, :away_minus, null));
    }
}

class AdjustScoreDelegate extends WatchUi.Menu2InputDelegate {
    var model;

    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    function onSelect(item) {
        if (item.getId() == :home_plus) {
            model.adjustScore(true, 1);
        } else if (item.getId() == :home_minus) {
            model.adjustScore(true, -1);
        } else if (item.getId() == :away_plus) {
            model.adjustScore(false, 1);
        } else if (item.getId() == :away_minus) {
            model.adjustScore(false, -1);
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class ScoreTeamMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Which Team?"});
        addItem(new WatchUi.MenuItem("Home", null, :team_home, null));
        addItem(new WatchUi.MenuItem("Away", null, :team_away, null));
    }
}

class ScoreTeamDelegate extends WatchUi.Menu2InputDelegate {
    var model;

    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    function onSelect(item) {
        var isHome = (item.getId() == :team_home);
        WatchUi.pushView(new ScoreTypeMenu(isHome), new ScoreTypeDelegate(model, isHome), WatchUi.SLIDE_UP);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class ScoreTypeMenu extends WatchUi.Menu2 {
    function initialize(isHome) {
        Menu2.initialize({:title=> isHome ? "Home Score" : "Away Score"});
        var model = Application.getApp().model;
        if (model != null && model.gameState == STATE_CONVERSION) {
            addItem(new WatchUi.MenuItem("Conversion Made", null, :conv_made, null));
            addItem(new WatchUi.MenuItem("Conversion Missed", null, :conv_miss, null));
        } else {
            addItem(new WatchUi.MenuItem("Try (5)", null, :score_try, null));
            addItem(new WatchUi.MenuItem("Conversion (2)", null, :score_conv, null));
            addItem(new WatchUi.MenuItem("Penalty (3)", null, :score_pen, null));
            addItem(new WatchUi.MenuItem("Drop Goal (3)", null, :score_drop, null));
        }
    }
}

class ScoreTypeDelegate extends WatchUi.Menu2InputDelegate {
    var model;
    var isHome;

    function initialize(m, homeFlag) {
        Menu2InputDelegate.initialize();
        model = m;
        isHome = homeFlag;
    }

    function onSelect(item) {
        if (item.getId() == :score_try) {
            model.recordTry(isHome);
        } else if (item.getId() == :score_conv) {
            model.recordConversion(isHome);
        } else if (item.getId() == :score_pen) {
            model.recordPenalty(isHome);
        } else if (item.getId() == :score_drop) {
            model.recordDropGoal(isHome);
        } else if (item.getId() == :conv_made) {
            model.recordConversion(isHome);
        } else if (item.getId() == :conv_miss) {
            model.endConversionWithoutScore();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN); // Close type
        WatchUi.popView(WatchUi.SLIDE_DOWN); // Close team
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class CardTeamMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Card Team"});
        addItem(new WatchUi.MenuItem("Home", null, :team_home, null));
        addItem(new WatchUi.MenuItem("Away", null, :team_away, null));
    }
}

class CardTeamDelegate extends WatchUi.Menu2InputDelegate {
    var model;
    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }
    function onSelect(item) {
        var isHome = (item.getId() == :team_home);
        WatchUi.pushView(new CardTypeMenu(isHome), new CardTypeDelegate(model, isHome), WatchUi.SLIDE_UP);
    }
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class CardTypeMenu extends WatchUi.Menu2 {
    function initialize(isHome) {
        Menu2.initialize({:title=> isHome ? "Home Card" : "Away Card"});
        addItem(new WatchUi.MenuItem("Yellow", null, :card_yellow, null));
        addItem(new WatchUi.MenuItem("Red", null, :card_red, null));
    }
}

class CardTypeDelegate extends WatchUi.Menu2InputDelegate {
    var model;
    var isHome;
    function initialize(m, homeFlag) {
        Menu2InputDelegate.initialize();
        model = m;
        isHome = homeFlag;
    }
    function onSelect(item) {
        if (item.getId() == :card_yellow) {
            model.recordYellowCard(isHome);
        } else if (item.getId() == :card_red) {
            model.recordRedCard(isHome);
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN); // type
        WatchUi.popView(WatchUi.SLIDE_DOWN); // team
    }
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class ExitMenuDelegate extends WatchUi.Menu2InputDelegate {
    var model;

    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    function onSelect(item) {
        if (item.getId() == :resume) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (item.getId() == :end) {
            model.endGame();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (item.getId() == :reset) {
            model.resetGame();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (item.getId() == :save_game) {
            model.saveGame();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (item.getId() == :view_log) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            model.showEventLog();
        } else if (item.getId() == :exit) {
            model.stopRecording();
            System.exit();
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class GameTypeMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Game Type"});
        addItem(new WatchUi.MenuItem("Rugby 7s", "7:00 halves", :gt_7s, null));
        addItem(new WatchUi.MenuItem("Rugby 15s", "40:00 halves", :gt_15s, null));
    }
}

class GameTypePromptDelegate extends WatchUi.Menu2InputDelegate {
    var model;

    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    function onSelect(item) {
        if (item.getId() == :gt_7s) {
            model.setGameType(true);
        } else if (item.getId() == :gt_15s) {
            model.setGameType(false);
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() {
        // Keep prompting on next show until a choice is made
        Application.getApp().rugbyView.promptedGameType = false;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class EventLogMenu extends WatchUi.Menu2 {
    function initialize(entries) {
        Menu2.initialize({:title=>"Event Log"});
        var itemsAdded = 0;
        if (entries != null && entries.size() > 0) {
            var start = entries.size() > 20 ? entries.size() - 20 : 0;
            for (var idx = start; idx < entries.size(); idx = idx + 1) {
                var entry = entries[idx] as Lang.Dictionary;
                var time = (entry != null && entry[:time] != null) ? entry[:time] : "--:--";
                var desc = (entry != null && entry[:desc] != null) ? entry[:desc] : "";
                addItem(new WatchUi.MenuItem(time + " – " + desc, null, :log_entry, null));
                itemsAdded += 1;
            }
        }
        if (itemsAdded == 0) {
            addItem(new WatchUi.MenuItem("No events recorded", null, :log_entry, null));
        }
        addItem(new WatchUi.MenuItem("Save Log", null, :save_log, null));
    }
}

class EventLogDelegate extends WatchUi.Menu2InputDelegate {
    var model;

    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    function onSelect(item) {
        if (item.getId() == :save_log) {
            model.exportEventLog();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
