using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;
using Toybox.Graphics;
using Toybox.Timer;
using Rez.Strings;

/**
 * The main delegate for the application.
 * It handles hardware input, overlay routing, and high-level navigation.
 *
 * Responsibility boundary:
 * keep device-button behavior here while menu/dialog classes live in
 * `RugbyTimerMenus`.
 */
class RugbyTimerDelegate extends WatchUi.BehaviorDelegate {
    var model;
    var overlayActionHandledUntil;
    var upMenuHoldTimer;
    var upMenuKeyPressed;
    var suppressNextUpMenuAction;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m) {
        BehaviorDelegate.initialize();
        model = m;
        overlayActionHandledUntil = 0;
        upMenuHoldTimer = null;
        upMenuKeyPressed = false;
        suppressNextUpMenuAction = false;
    }

    function cancelUpMenuHoldTimer() {
        upMenuKeyPressed = false;
        if (upMenuHoldTimer != null) {
            upMenuHoldTimer.stop();
            upMenuHoldTimer = null;
        }
    }

    function showPresetMenu() as Void {
        WatchUi.pushView(new MatchProfileMenu(), new MatchProfileDelegate(null, false), WatchUi.SLIDE_UP);
        WatchUi.requestUpdate();
    }

    function handleUpMenuHoldTimer() as Void {
        var view = Application.getApp().rugbyView;
        if (!upMenuKeyPressed || view == null || view.isLocked || view.isSpecialOverlayActive()) {
            return;
        }
        suppressNextUpMenuAction = true;
        cancelUpMenuHoldTimer();
        showPresetMenu();
    }

    /**
     * Logs and swallows input failures so one bad state transition does not crash the app.
     * @param context Short label describing the failing input path
     * @param ex The raised exception
     * @return true after the failure is handled
     */
    function handleInputFailure(context, ex) {
        var view = Application.getApp().rugbyView;
        System.println("Input failure (" + context + "): " + ex.getErrorMessage());
        model.setStatusMessage(RugbyStrings.load(Rez.Strings.Status_ActionFailed));
        if (view != null && view.isSpecialOverlayActive()) {
            view.closeSpecialTimerScreen();
        }
        WatchUi.requestUpdate();
        return true;
    }

    /**
     * Runs overlay actions through one guarded path so different hardware mappings
     * cannot send the app into inconsistent state transitions.
     * @param action The logical overlay action
     * @return true after the input is consumed
     */
    function handleOverlayAction(action) {
        var view = Application.getApp().rugbyView;
        if (view == null) {
            return true;
        }
        var now = System.getTimer();
        if (overlayActionHandledUntil != null && now < overlayActionHandledUntil) {
            return true;
        }
        overlayActionHandledUntil = now + 500;
        try {
            view.closeSpecialTimerScreen();
            if (model.gameState == STATE_CONVERSION) {
                if (action == :made) {
                    model.handleConversionSuccess();
                } else if (action == :miss) {
                    model.handleConversionMiss();
                }
                WatchUi.requestUpdate();
                return true;
            }
            if (model.gameState == STATE_PENALTY) {
                WatchUi.requestUpdate();
                return true;
            }
        } catch (ex) {
            return handleInputFailure("overlay_" + action.toString(), ex);
        }
        return true;
    }

    /**
     * Handles raw hardware keys during overlays so fenix button mappings do not fall
     * through to unrelated behaviors or device defaults.
     * @param evt The key event
     * @return true if handled, false otherwise
     */
    function onKey(evt) {
        try {
            var view = Application.getApp().rugbyView;
            if (view == null || view.isLocked) {
                return false;
            }

            if (!view.isSpecialOverlayActive() && model.gameState == STATE_IDLE) {
                var idleKey = evt.getKey();
                if (idleKey == WatchUi.KEY_UP) {
                    return onPreviousPage();
                }
                if (idleKey == WatchUi.KEY_DOWN) {
                    return onNextPage();
                }
                return false;
            }

            if (!view.isSpecialOverlayActive()) {
                return false;
            }

            if (!view.isActionAllowed()) {
                return true;
            }

            var key = evt.getKey();
            var overlayAction = RugbyTimerInputSupport.getOverlayActionForKey(model.gameState, key);
            if (overlayAction != null) {
                return handleOverlayAction(overlayAction);
            }
            return false;
        } catch (ex) {
            return handleInputFailure("key", ex);
        }
    }

    function onKeyPressed(evt) {
        try {
            var view = Application.getApp().rugbyView;
            if (view == null || view.isLocked || view.isSpecialOverlayActive()) {
                return false;
            }
            if (RugbyTimerInputSupport.shouldStartPresetHold(evt.getKey())) {
                cancelUpMenuHoldTimer();
                upMenuKeyPressed = true;
                upMenuHoldTimer = new Timer.Timer();
                upMenuHoldTimer.start(method(:handleUpMenuHoldTimer), 700, false);
            }
            return false;
        } catch (ex) {
            return handleInputFailure("key_pressed", ex);
        }
    }

    function onKeyReleased(evt) {
        try {
            if (evt.getKey() == WatchUi.KEY_MENU || evt.getKey() == WatchUi.KEY_UP) {
                cancelUpMenuHoldTimer();
                return suppressNextUpMenuAction;
            }
            return false;
        } catch (ex) {
            return handleInputFailure("key_released", ex);
        }
    }

    /**
     * This method is called when the menu button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onMenu() {
        try {
            var view = Application.getApp().rugbyView;
            cancelUpMenuHoldTimer();
            if (suppressNextUpMenuAction) {
                suppressNextUpMenuAction = false;
                return true;
            }
            if (view.isLocked) {
                return true;
            }
            if (view.isSpecialOverlayActive()) {
                if (!view.isActionAllowed()) {
                    return true;
                }
                if (model.gameState == STATE_CONVERSION) {
                    return handleOverlayAction(:made);
                } else if (model.gameState == STATE_PENALTY) {
                    return handleOverlayAction(:hide);
                }
                return true;
            }

            // Before kickoff only, map UP/MENU to +1 minute adjustment.
            if (model.gameState == STATE_IDLE) {
                var newMinutes = RugbyTimerInputSupport.getAdjustedIdleMinutes(model.countdownTimer, 1);
                model.setHalfDuration(newMinutes * 60);
                WatchUi.requestUpdate();
                return true;
            }

            WatchUi.pushView(new Rez.Menus.MainMenu(), new MainMenuDelegate(model), WatchUi.SLIDE_UP);
            return true;
        } catch (ex) {
            return handleInputFailure("menu", ex);
        }
    }

    /**
     * This method is called when the select button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onSelect() {
        var view = Application.getApp().rugbyView;
        if (view == null) { return true; }
        if (view.isLocked) {
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
    function onBack() {
        var view = Application.getApp().rugbyView;
        if (view == null) { return false; }
        if (view.isLocked) {
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

    /**
     * This method is called when the next page button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onNextPage() {
        var view = Application.getApp().rugbyView;
        if (view == null) { return true; }
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
    function onPreviousPage() {
        var view = Application.getApp().rugbyView;
        if (view == null) { return true; }
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
    var model;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item) {
        var view = Application.getApp().rugbyView;
        if (view == null) { WatchUi.popView(WatchUi.SLIDE_DOWN); return; }
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
    var model;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
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
    var model;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item) {
        var isHome = (item.getId() == :team_home);
        WatchUi.pushView(new ScoreTypeMenu(isHome), new ScoreTypeDelegate(model, isHome), WatchUi.SLIDE_UP);
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
            addItem(new WatchUi.MenuItem("Penalty Try (7)", null, :score_pen_try, null));
            addItem(new WatchUi.MenuItem("Drop Goal (3)", null, :score_drop, null));
        }
    }
}

/**
 * Delegate for the score type menu.
 */
class ScoreTypeDelegate extends WatchUi.Menu2InputDelegate {
    var model;
    var isHome;

    /**
     * Initializes the delegate.
     * @param m The game model
     * @param homeFlag A boolean indicating if the home team is scoring
     */
    function initialize(m, homeFlag) {
        Menu2InputDelegate.initialize();
        model = m;
        isHome = homeFlag;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item) {
        if (item.getId() == :score_try) {
            model.recordTry(isHome);
        } else if (item.getId() == :score_conv) {
            model.recordConversion(isHome);
        } else if (item.getId() == :score_pen) {
            model.recordPenalty(isHome);
        } else if (item.getId() == :score_pen_try) {
            model.recordPenaltyTry(isHome);
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
    var model;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item) {
        var isHome = (item.getId() == :team_home);
        WatchUi.pushView(new CardTypeMenu(isHome), new CardTypeDelegate(model, isHome), WatchUi.SLIDE_UP);
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
    var model;
    var isHome;

    /**
     * Initializes the delegate.
     * @param m The game model
     * @param homeFlag A boolean indicating if the home team is receiving the card
     */
    function initialize(m, homeFlag) {
        Menu2InputDelegate.initialize();
        model = m;
        isHome = homeFlag;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item) {
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
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Delegate for the exit menu.
 */
class ExitMenuDelegate extends WatchUi.Menu2InputDelegate {
    var model;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
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

    /**
     * This method is called when the back button is pressed.
     */
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
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
        addItem(new WatchUi.MenuItem("Rugby 7s", "2 min yellows", :gt_7s, null));
        addItem(new WatchUi.MenuItem("Rugby 15s", "10 min yellows", :gt_15s, null));
    }
}

/**
 * Delegate for the game type prompt.
 */
class GameTypePromptDelegate extends WatchUi.Menu2InputDelegate {
    var model;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item) {
        var is7s = (item.getId() == :gt_7s);
        // Pre-fill picker with the saved duration for this game type (FR-005)
        var typeKey = is7s ? "halfDuration7s" : "halfDuration15s";
        var savedSecs = Storage.getValue(typeKey);
        if (savedSecs == null) {
            savedSecs = Storage.getValue("countdownTimer"); // legacy fallback
        }
        var defaultMinutes = (savedSecs != null) ? (savedSecs / 60) : (is7s ? 7 : 40);
        if (defaultMinutes < 1) { defaultMinutes = 1; }
        WatchUi.pushView(new MinutesPicker(defaultMinutes), new NewGameTimerPickerDelegate(is7s, model), WatchUi.SLIDE_UP);
    }

    /**
     * This method is called when the back button is pressed.
     */
    function onBack() {
        // Keep prompting on next show until a choice is made
        var v = Application.getApp().rugbyView;
        if (v != null) { v.promptedGameType = false; }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Picker delegate for the new-game setup flow.
 * Finalises both game type and half length, then returns to the watch face.
 */
class NewGameTimerPickerDelegate extends WatchUi.PickerDelegate {
    var mModel;
    var mIs7s;

    function initialize(is7sFlag, m) {
        PickerDelegate.initialize();
        mIs7s = is7sFlag;
        mModel = m;
    }

    function onAccept(values) {
        if (values == null || values.size() < 2) { WatchUi.popView(WatchUi.SLIDE_DOWN); return true; }
        var minutes = values[0] * 10 + values[1];
        if (minutes < 1) { minutes = 1; }
        mModel.setGameType(mIs7s);
        mModel.setHalfDuration(minutes * 60);
        // Pop picker then the game-type menu
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onCancel() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
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
    function initialize(entries as Lang.Array) {
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

/**
 * Delegate for the event log menu.
 */
class EventLogDelegate extends WatchUi.Menu2InputDelegate {
    var model;

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    /**
     * This method is called when a menu item is selected.
     * @param item The selected menu item
     */
    function onSelect(item) {
        if (item.getId() == :save_log) {
            model.exportEventLog();
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