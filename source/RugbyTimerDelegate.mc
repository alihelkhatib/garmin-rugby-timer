using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;

/**
 * The main delegate for the application.
 * It handles user input and dispatches actions to the model.
 */
class RugbyTimerDelegate extends WatchUi.BehaviorDelegate {
    var model as RugbyGameModel;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m as RugbyGameModel) {
        BehaviorDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when the menu button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new MainMenuDelegate(model as RugbyGameModel), WatchUi.SLIDE_UP);
        return true;
    }

    /**
     * This method is called when the select button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onSelect() as Boolean {
        var app = Application.getApp() as RugbyTimerApp;
        if (app.rugbyView.isLocked) {
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

    /**
     * This method is called when the back button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onBack() as Boolean {
        var app = Application.getApp() as RugbyTimerApp;
        if (app.rugbyView.isLocked) {
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
            WatchUi.pushView(menu, new ExitMenuDelegate(model as RugbyGameModel), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }

    /**
     * This method is called when the next page button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onNextPage() as Boolean {
        var view = Application.getApp().rugbyView as RugbyTimerView;
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

    /**
     * This method is called when the previous page button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onPreviousPage() as Boolean {
        var view = Application.getApp().rugbyView as RugbyTimerView;
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

/**
 * Delegate for the main menu.
 */
class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    var model as RugbyGameModel;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m as RugbyGameModel) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item as WatchUi.MenuItem) as Void {
        var view = Application.getApp().rugbyView as RugbyTimerView;
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
            WatchUi.pushView(new AdjustScoreMenu(), new AdjustScoreDelegate(model as RugbyGameModel), WatchUi.SLIDE_UP);
            return;
        } else if (item.getId() == :toggle_lock) {
            view.toggleLock();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    /**
     * This method is called when the back button is pressed.
     */
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Menu for adjusting the score.
 */
class AdjustScoreMenu extends WatchUi.Menu2 {
    /**
     * Initializes the menu.
     */
    function initialize() {
        Menu2.initialize({:title=>"Adjust Score"});
        addItem(new WatchUi.MenuItem("Home +1", null, :home_plus, null));
        addItem(new WatchUi.MenuItem("Home -1", null, :home_minus, null));
        addItem(new WatchUi.MenuItem("Away +1", null, :away_plus, null));
        addItem(new WatchUi.MenuItem("Away -1", null, :away_minus, null));
    }
}

/**
 * Delegate for the adjust score menu.
 */
class AdjustScoreDelegate extends WatchUi.Menu2InputDelegate {
    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m as RugbyGameModel) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item as WatchUi.MenuItem) as Void {
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

    /**
     * This method is called when the back button is pressed.
     */
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Menu for selecting a team to score.
 */
class ScoreTeamMenu extends WatchUi.Menu2 {
    /**
     * Initializes the menu.
     */
    function initialize() {
        Menu2.initialize({:title=>"Which Team?"});
        addItem(new WatchUi.MenuItem("Home", null, :team_home, null));
        addItem(new WatchUi.MenuItem("Away", null, :team_away, null));
    }
}

/**
 * Delegate for the score team menu.
 */
class ScoreTeamDelegate extends WatchUi.Menu2InputDelegate {
    var model as RugbyGameModel;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m as RugbyGameModel) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item as WatchUi.MenuItem) as Void {
        var isHome = (item.getId() == :team_home) as Boolean;
        WatchUi.pushView(new ScoreTypeMenu(isHome), new ScoreTypeDelegate(model as RugbyGameModel, isHome), WatchUi.SLIDE_UP);
    }

    /**
     * This method is called when the back button is pressed.
     */
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Menu for selecting the type of score.
 */
class ScoreTypeMenu extends WatchUi.Menu2 {
    /**
     * Initializes the menu.
     * @param isHome A boolean indicating if the home team is scoring
     */
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

/**
 * Delegate for the score type menu.
 */
class ScoreTypeDelegate extends WatchUi.Menu2InputDelegate {
    var model as RugbyGameModel;
    var isHome as Boolean;

    /**
     * Initializes the delegate.
     * @param m The game model
     * @param homeFlag A boolean indicating if the home team is scoring
     */
    function initialize(m as RugbyGameModel, homeFlag as Boolean) as Void {
        Menu2InputDelegate.initialize();
        model = m;
        isHome = homeFlag;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item as WatchUi.MenuItem) as Void {
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

    /**
     * This method is called when the back button is pressed.
     */
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Menu for selecting a team for a card.
 */
class CardTeamMenu extends WatchUi.Menu2 {
    /**
     * Initializes the menu.
     */
    function initialize() {
        Menu2.initialize({:title=>"Card Team"});
        addItem(new WatchUi.MenuItem("Home", null, :team_home, null));
        addItem(new WatchUi.MenuItem("Away", null, :team_away, null));
    }
}

/**
 * Delegate for the card team menu.
 */
class CardTeamDelegate extends WatchUi.Menu2InputDelegate {
    var model as RugbyGameModel;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m as RugbyGameModel) as Void {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item as WatchUi.MenuItem) as Void {
        var isHome = (item.getId() == :team_home) as Boolean;
        WatchUi.pushView(new CardTypeMenu(isHome), new CardTypeDelegate(model as RugbyGameModel, isHome), WatchUi.SLIDE_UP);
    }

    /**
     * This method is called when the back button is pressed.
     */
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Menu for selecting the type of card.
 */
class CardTypeMenu extends WatchUi.Menu2 {
    /**
     * Initializes the menu.
     * @param isHome A boolean indicating if the home team is receiving the card
     */
    function initialize(isHome) {
        Menu2.initialize({:title=> isHome ? "Home Card" : "Away Card"});
        addItem(new WatchUi.MenuItem("Yellow", null, :card_yellow, null));
        addItem(new WatchUi.MenuItem("Red", null, :card_red, null));
    }
}

/**
 * Delegate for the card type menu.
 */
class CardTypeDelegate extends WatchUi.Menu2InputDelegate {
    var model as RugbyGameModel;
    var isHome as Boolean;

    /**
     * Initializes the delegate.
     * @param m The game model
     * @param homeFlag A boolean indicating if the home team is receiving the card
     */
    function initialize(m as RugbyGameModel, homeFlag as Boolean) as Void {
        Menu2InputDelegate.initialize();
        model = m;
        isHome = homeFlag;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :card_yellow) {
            model.recordYellowCard(isHome);
        } else if (item.getId() == :card_red) {
            model.recordRedCard(isHome);
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN); // type
        WatchUi.popView(WatchUi.SLIDE_DOWN); // team
    }

    /**
     * This method is called when the back button is pressed.
     */
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Delegate for the exit menu.
 */
    /**
     * This method is called when the back button is pressed.
     */
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

/**
 * Menu for selecting the game type.
 */
class GameTypeMenu extends WatchUi.Menu2 {
    /**
     * Initializes the menu.
     */
    function initialize() {
        Menu2.initialize({:title=>"Game Type"});
        addItem(new WatchUi.MenuItem("Rugby 7s", "7:00 halves", :gt_7s, null));
        addItem(new WatchUi.MenuItem("Rugby 15s", "40:00 halves", :gt_15s, null));
    }
}

/**
 * Delegate for the game type prompt.
 */
class GameTypePromptDelegate extends WatchUi.Menu2InputDelegate {
    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m as RugbyGameModel) as Void {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :gt_7s) {
            model.setGameType(true);
        } else if (item.getId() == :gt_15s) {
            model.setGameType(false);
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    /**
     * This method is called when the back button is pressed.
     */
    function onBack() as Void {
        // Keep prompting on next show until a choice is made
        Application.getApp().rugbyView.promptedGameType = false;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Menu for displaying the event log.
 */
class EventLogMenu extends WatchUi.Menu2 {
    /**
     * Initializes the menu.
     * @param entries The event log entries
     */
    function initialize(entries as Array<Dictionary> or Null) as Void {
        Menu2.initialize({:title=>"Event Log"});
        var itemsAdded = 0;
        if (entries != null && entries.size() > 0) {
            var start = entries.size() > 20 ? entries.size() - 20 : 0;
            for (var idx = start; idx < entries.size(); idx = idx + 1) {
                var entry = entries[idx] as Lang.Dictionary or Null;
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

/**
 * Delegate for the event log menu.
 */
    /**
     * This method is called when the back button is pressed.
     */
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
