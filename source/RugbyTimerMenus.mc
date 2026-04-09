using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;
using Toybox.Timer;
using Rez.Strings;

/**
 * Menu and dialog classes for the in-match interaction stack.
 *
 * Purpose: keep menu-driven scoring/card/log/exit flows out of
 * `RugbyTimerDelegate` so the delegate remains centered on hardware input.
 */
/**
 * Shared failure handler for menu/delegate paths in the match-menu stack.
 */
function handleMenuDelegateFailure(context) {
    System.println("Menu delegate failure (" + context + ")");
    WatchUi.requestUpdate();
    return true;
}

/**
 * Delegate for the in-match main menu.
 *
 * Responsibility boundary:
 * handle menu-driven actions only. Raw hardware input stays in
 * `RugbyTimerDelegate`.
 */
class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    var model;
    var presetOpenTimer;

    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
        presetOpenTimer = null;
    }

    function showPresetAfterMenuClose() as Void {
        presetOpenTimer = null;
        WatchUi.pushView(new MatchProfileMenu(), new MatchProfileDelegate(null, false), WatchUi.SLIDE_UP);
        WatchUi.requestUpdate();
    }

    function openPresetFromMenu() {
        if (presetOpenTimer != null) {
            presetOpenTimer.stop();
        }
        presetOpenTimer = new Timer.Timer();
        presetOpenTimer.start(method(:showPresetAfterMenuClose) as Method() as Void, 50, false);
    }

    function onSelect(item) {
        try {
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
            } else if (item.getId() == :settings) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                openPresetFromMenu();
                return;
            } else if (item.getId() == :toggle_lock) {
                view.toggleLock();
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } catch (ex) {
            handleMenuDelegateFailure("main_select");
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class ScoreTeamMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>RugbyStrings.load(Rez.Strings.ScoreTeam_Title)});
        addItem(new WatchUi.MenuItem(RugbyStrings.getTeamMenuLabel(true), null, :team_home, null));
        addItem(new WatchUi.MenuItem(RugbyStrings.getTeamMenuLabel(false), null, :team_away, null));
    }
}

/**
 * First step in the score-recording flow: choose the scoring team.
 */
class ScoreTeamDelegate extends WatchUi.Menu2InputDelegate {
    var model;

    function initialize(m) {
        Menu2InputDelegate.initialize();
        model = m;
    }

    function onSelect(item) {
        try {
            var isHome = (item.getId() == :team_home);
            WatchUi.pushView(new ScoreTypeMenu(isHome), new ScoreTypeDelegate(model, isHome), WatchUi.SLIDE_UP);
        } catch (ex) {
            handleMenuDelegateFailure("score_team_select");
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Second step in the score-recording flow: choose the score type.
 */
class ScoreTypeMenu extends WatchUi.Menu2 {
    function initialize(isHome) {
        Menu2.initialize({:title=> isHome ? RugbyStrings.load(Rez.Strings.ScoreTeam_HomeTitle) : RugbyStrings.load(Rez.Strings.ScoreTeam_AwayTitle)});
        addItem(new WatchUi.MenuItem(RugbyStrings.load(Rez.Strings.ScoreType_Try), null, :score_try, null));
        addItem(new WatchUi.MenuItem(RugbyStrings.load(Rez.Strings.ScoreType_PenaltyTry), null, :score_pen_try, null));
        addItem(new WatchUi.MenuItem(RugbyStrings.load(Rez.Strings.ScoreType_DropGoal), null, :score_drop, null));
    }
}

/**
 * Applies the selected score type and closes the two-level score flow.
 */
class ScoreTypeDelegate extends WatchUi.Menu2InputDelegate {
    var model;
    var isHome;

    function initialize(m, homeFlag) {
        Menu2InputDelegate.initialize();
        model = m;
        isHome = homeFlag;
    }

    function onSelect(item) {
        try {
            if (item.getId() == :score_try) {
                model.recordTry(isHome);
            } else if (item.getId() == :score_pen_try) {
                model.recordPenaltyTry(isHome);
            } else if (item.getId() == :score_drop) {
                model.recordDropGoal(isHome);
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.requestUpdate();
        } catch (ex) {
            handleMenuDelegateFailure("score_type_select");
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * First step in the card-recording flow: choose the sanctioned team.
 */
class CardTeamMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>RugbyStrings.load(Rez.Strings.CardTeam_Title)});
        addItem(new WatchUi.MenuItem(RugbyStrings.getTeamMenuLabel(true), null, :team_home, null));
        addItem(new WatchUi.MenuItem(RugbyStrings.getTeamMenuLabel(false), null, :team_away, null));
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

/**
 * Second step in the card-recording flow: choose yellow or red.
 */
class CardTypeMenu extends WatchUi.Menu2 {
    function initialize(isHome) {
        Menu2.initialize({:title=> isHome ? RugbyStrings.load(Rez.Strings.CardTeam_HomeTitle) : RugbyStrings.load(Rez.Strings.CardTeam_AwayTitle)});
        addItem(new WatchUi.MenuItem(RugbyStrings.load(Rez.Strings.CardType_Yellow), null, :card_yellow, null));
        addItem(new WatchUi.MenuItem(RugbyStrings.load(Rez.Strings.CardType_Red), null, :card_red, null));
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
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Delegate for the match exit dialog.
 */
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
            System.exit();
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

/**
 * Read-only event-log menu plus export action.
 */
class EventLogMenu extends WatchUi.Menu2 {
    function initialize(entries as Lang.Array) {
        Menu2.initialize({:title=>RugbyStrings.load(Rez.Strings.EventLog_Title)});
        var itemsAdded = 0;
        if (entries != null && entries.size() > 0) {
            var start = entries.size() > 20 ? entries.size() - 20 : 0;
            for (var idx = start; idx < entries.size(); idx = idx + 1) {
                var label = RugbyTimerEventLog.formatStoredEntry(entries[idx]);
                if (label == null) { label = RugbyStrings.load(Rez.Strings.EventLog_NoTime); }
                addItem(new WatchUi.MenuItem(label, null, :log_entry, null));
                itemsAdded += 1;
            }
        }
        if (itemsAdded == 0) {
            addItem(new WatchUi.MenuItem(RugbyStrings.load(Rez.Strings.EventLog_Empty), null, :log_entry, null));
        }
        addItem(new WatchUi.MenuItem(RugbyStrings.load(Rez.Strings.EventLog_Save), null, :save_log, null));
    }
}

/**
 * Handles the event-log export action.
 */
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
