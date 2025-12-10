using Toybox.WatchUi;
using Toybox.System;

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
        if (view.isLocked) {
            return true;
        }
        // Start/pause/resume game with select button
        if (view.gameState == STATE_IDLE) {
            view.startGame();
        } else if (view.gameState == STATE_PLAYING) {
            view.pauseGame();
        } else if (view.gameState == STATE_PAUSED) {
            view.resumeGame();
        } else if (view.gameState == STATE_HALFTIME) {
            view.startSecondHalf();
        }
        return true;
    }

    function onBack() {
        if (view.isLocked) {
            return true;
        }
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
        if (view.isLocked || !view.isActionAllowed()) {
            return true;
        }
        if (view.gameState == STATE_CONVERSION) {
            view.handleConversionMiss();
        } else {
            view.showCardDialog();
        }
        return true;
    }

    function onPreviousPage() {
        if (view.isLocked || !view.isActionAllowed()) {
            return true;
        }
        if (view.gameState == STATE_CONVERSION) {
            view.handleConversionSuccess();
        } else {
            view.showScoreDialog();
        }
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
        if (item.getId() == :record_score) {
            view.showScoreDialog();
        } else if (item.getId() == :record_card) {
            view.showCardDialog();
        } else if (item.getId() == :pause_clock) {
            if (view.gameState == STATE_PAUSED) {
                view.resumeClock();
            } else {
                view.pauseClock();
            }
        } else if (item.getId() == :start_half2) {
            view.startSecondHalf();
        } else if (item.getId() == :end_game) {
            view.endGame();
        } else if (item.getId() == :undo_last) {
            view.undoLastEvent();
        } else if (item.getId() == :adjust_score) {
            WatchUi.pushView(new AdjustScoreMenu(), new AdjustScoreDelegate(view), WatchUi.SLIDE_UP);
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
    var view;

    function initialize(v) {
        Menu2InputDelegate.initialize();
        view = v;
    }

    function onSelect(item) {
        if (item.getId() == :home_plus) {
            view.adjustScore(true, 1);
        } else if (item.getId() == :home_minus) {
            view.adjustScore(true, -1);
        } else if (item.getId() == :away_plus) {
            view.adjustScore(false, 1);
        } else if (item.getId() == :away_minus) {
            view.adjustScore(false, -1);
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
    var view;

    function initialize(v) {
        Menu2InputDelegate.initialize();
        view = v;
    }

    function onSelect(item) {
        var isHome = (item.getId() == :team_home);
        WatchUi.pushView(new ScoreTypeMenu(isHome), new ScoreTypeDelegate(view, isHome), WatchUi.SLIDE_UP);
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class ScoreTypeMenu extends WatchUi.Menu2 {
    function initialize(isHome) {
        Menu2.initialize({:title=> isHome ? "Home Score" : "Away Score"});
        var view = Application.getApp().rugbyView;
        if (view != null && view.gameState == STATE_CONVERSION) {
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
    var view;
    var isHome;

    function initialize(v, homeFlag) {
        Menu2InputDelegate.initialize();
        view = v;
        isHome = homeFlag;
    }

    function onSelect(item) {
        if (item.getId() == :score_try) {
            view.recordTry(isHome);
        } else if (item.getId() == :score_conv) {
            view.recordConversion(isHome);
        } else if (item.getId() == :score_pen) {
            view.recordPenalty(isHome);
        } else if (item.getId() == :score_drop) {
            view.recordDropGoal(isHome);
        } else if (item.getId() == :conv_made) {
            view.recordConversion(isHome);
        } else if (item.getId() == :conv_miss) {
            view.endConversionWithoutScore();
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
    var view;
    function initialize(v) {
        Menu2InputDelegate.initialize();
        view = v;
    }
    function onSelect(item) {
        var isHome = (item.getId() == :team_home);
        WatchUi.pushView(new CardTypeMenu(isHome), new CardTypeDelegate(view, isHome), WatchUi.SLIDE_UP);
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
    var view;
    var isHome;
    function initialize(v, homeFlag) {
        Menu2InputDelegate.initialize();
        view = v;
        isHome = homeFlag;
    }
    function onSelect(item) {
        if (item.getId() == :card_yellow) {
            view.recordYellowCard(isHome);
        } else if (item.getId() == :card_red) {
            view.recordRedCard(isHome);
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN); // type
        WatchUi.popView(WatchUi.SLIDE_DOWN); // team
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
        } else if (item.getId() == :reset) {
            view.resetGame();
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

class GameTypeMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Game Type"});
        addItem(new WatchUi.MenuItem("Rugby 7s", "7:00 halves", :gt_7s, null));
        addItem(new WatchUi.MenuItem("Rugby 15s", "40:00 halves", :gt_15s, null));
    }
}

class GameTypePromptDelegate extends WatchUi.Menu2InputDelegate {
    var view;

    function initialize(v) {
        Menu2InputDelegate.initialize();
        view = v;
    }

    function onSelect(item) {
        if (item.getId() == :gt_7s) {
            view.setGameType(true);
        } else if (item.getId() == :gt_15s) {
            view.setGameType(false);
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() {
        // Keep prompting on next show until a choice is made
        view.promptedGameType = false;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
