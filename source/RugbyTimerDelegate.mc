using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;
using Toybox.Graphics;

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

    /**
     * Initializes the delegate.
     * @param m The game model
     */
    function initialize(m) {
        BehaviorDelegate.initialize();
        model = m;
        overlayActionHandledUntil = 0;
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
        model.setStatusMessage("Action failed");
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

    /**
     * This method is called when the menu button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onMenu() {
        try {
            var view = Application.getApp().rugbyView;
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
                if (!view.isActionAllowed()) {
                    return true;
                }
                var newMinutes = RugbyTimerInputSupport.getAdjustedIdleMinutes(model.countdownTimer, 1);
                model.setHalfDuration(newMinutes * 60);
                return true;
            }

            if (model.gameState == STATE_HALFTIME) {
                if (!view.isActionAllowed()) {
                    return true;
                }
                model.adjustHalfTimeBreak(1);
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
        try {
            var view = Application.getApp().rugbyView;
            if (view.isLocked) {
                return true;
            }
            // Start/pause/resume game with select button
            var selectAction = RugbyMatchStateSupport.getSelectAction(model.gameState);
            if (selectAction == :start_game) {
                model.startGame();
                if (model.lockOnStart && !view.isLocked) {
                    view.toggleLock();
                }
            } else if (selectAction == :pause_clock) {
                model.pauseClock();
            } else if (selectAction == :resume_clock) {
                model.resumeClock();
            } else if (selectAction == :start_half2) {
                model.startSecondHalf();
                if (model.lockOnStart && !view.isLocked) {
                    view.toggleLock();
                }
            }
            return true;
        } catch (ex) {
            return handleInputFailure("select", ex);
        }
    }

    /**
     * This method is called when the back button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onBack() {
        try {
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
        } catch (ex) {
            return handleInputFailure("back", ex);
        }
    }

    /**
     * This method is called when the next page button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onNextPage() {
        try {
            var view = Application.getApp().rugbyView;
            if (view.isLocked || !view.isActionAllowed()) {
                return true;
            }
            // Physical DOWN should shorten the idle half length by one minute.
            if (model.gameState == STATE_IDLE) {
                var newMinutes = RugbyTimerInputSupport.getAdjustedIdleMinutes(model.countdownTimer, -1);
                model.setHalfDuration(newMinutes * 60);
                return true;
            }
            if (model.gameState == STATE_HALFTIME) {
                model.adjustHalfTimeBreak(-1);
                return true;
            }
            if (model.gameState == STATE_PENALTY) {
                if (view.isSpecialOverlayActive()) {
                    handleOverlayAction(:hide);
                }
                return true;
            }
            if (view.isSpecialOverlayActive() && model.gameState == STATE_CONVERSION) {
                return handleOverlayAction(:miss);
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
        } catch (ex) {
            return handleInputFailure("next_page", ex);
        }
    }

    /**
     * This method is called when the previous page button is pressed.
     * @return true if the event is handled, false otherwise
     */
    function onPreviousPage() {
        try {
            var view = Application.getApp().rugbyView;
            if (view.isLocked || !view.isActionAllowed()) {
                return true;
            }
            // Physical UP should lengthen the idle half length by one minute.
            if (model.gameState == STATE_IDLE) {
                var newMinutes = RugbyTimerInputSupport.getAdjustedIdleMinutes(model.countdownTimer, 1);
                model.setHalfDuration(newMinutes * 60);
                return true;
            }
            if (model.gameState == STATE_HALFTIME) {
                model.adjustHalfTimeBreak(1);
                return true;
            }
            if (model.gameState == STATE_PENALTY) {
                if (view.isSpecialOverlayActive()) {
                    handleOverlayAction(:hide);
                }
                return true;
            }
            if (view.isSpecialOverlayActive() && model.gameState == STATE_CONVERSION) {
                return handleOverlayAction(:made);
            }
            if (view.isSpecialOverlayActive()) {
                return true;
            }
            if (model.gameState == STATE_CONVERSION) {
                return true;
            } else {
                view.showScoreDialog();
            }
            return true;
        } catch (ex) {
            return handleInputFailure("previous_page", ex);
        }
    }
}
