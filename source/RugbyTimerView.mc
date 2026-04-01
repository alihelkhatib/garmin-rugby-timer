using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Timer;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application.Storage;
using Rez.Strings;

/**
 * Represents the main view of the rugby timer application.
 * This class is responsible for rendering the UI based on the data from the model.
 * It also handles some UI-specific state, such as screen lock and overlay visibility.
 */
class RugbyTimerView extends WatchUi.View {
    // The game model
    var model as RugbyGameModel;
    
    // Cached font information
    var cachedFonts as Toybox.Lang.Dictionary = {} as Toybox.Lang.Dictionary;
    // Cached layout information
    var cachedLayout as Toybox.Lang.Dictionary = {} as Toybox.Lang.Dictionary;

    // A boolean indicating if the screen is locked
    var isLocked;
    // A boolean indicating if the screen is in dim mode
    var dimMode;
    // The timestamp of the last user action
    var lastActionTs;
    // A boolean indicating if the special timer overlay is visible
    var specialTimerOverlayVisible;
    // The message to be displayed on the special overlay
    var specialOverlayMessage;
    // The expiry timestamp for the special overlay message
    var specialOverlayMessageExpiry;
    
    // The timer for updating the game state
    var updateTimer;
    
    /**
     * Initializes the view.
     * @param m The game model
     */
    function initialize(m) {
        View.initialize();
        model = m;
        
        isLocked = false;
        lastActionTs = 0;
        specialTimerOverlayVisible = false;
        specialOverlayMessage = null;
        specialOverlayMessageExpiry = 0;
        dimMode = Storage.getValue("dimMode");
        if (dimMode == null) { dimMode = false; }
    }

    /**
     * This method is called when the view is laid out.
     * @param dc The device context
     */
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
        // Calculate and cache fonts and layout once
        cachedFonts = RugbyTimerRenderer.chooseFonts(dc.getWidth());
        cachedLayout = RugbyTimerRenderer.calculateLayout(dc.getHeight());
    }

    /**
     * This method is called when the view is shown.
     */
    function onShow() {
        if (updateTimer == null) {
            updateTimer = new Timer.Timer();
            updateTimer.start(method(:updateGame), 100, true);
        }
    }

    /**
     * Simple debounce for adjustments/quick actions.
     * Simple debounce gate to prevent rapid repeated actions from hardware buttons.
     * @return true if the action is allowed, false otherwise
     */
    function isActionAllowed() {
        var now = System.getTimer();
        if (lastActionTs == null || now - lastActionTs > 300) {
            lastActionTs = now;
            return true;
        }
        return false;
    }

    /**
     * This method is called to update the view.
     * @param dc The device context
     */
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();

        // Conversion overlays should reopen automatically when a try transitions the
        // model into conversion state, even if that happened while a menu was on top.
        if (model.gameState == STATE_CONVERSION && !specialTimerOverlayVisible) {
            specialTimerOverlayVisible = true;
        } else if (specialTimerOverlayVisible && model.gameState != STATE_CONVERSION && model.gameState != STATE_PENALTY) {
            specialTimerOverlayVisible = false;
        }

        // Use cached fonts and layout
        var fonts = cachedFonts;
        var layout = cachedLayout;

        RugbyTimerRenderer.renderScores(dc, model, width, fonts[:scoreFont], layout[:scoreY]);
        RugbyTimerRenderer.renderGameTimer(dc, model, width, fonts[:timerFont], layout[:gameTimerY]);
        RugbyTimerRenderer.renderHalfAndTries(dc, model, width, fonts[:halfFont], fonts[:triesFont], layout[:halfY], layout[:triesY]);
        RugbyTimerRenderer.renderPlayPauseIndicator(dc, model, width, height, layout[:iconY]);
        if (isLocked) {
            RugbyTimerRenderer.renderLockIndicator(dc, width, height, layout[:scoreY]);
        }

        var cardInfo = RugbyTimerRenderer.renderCardTimers(dc, model, width, layout[:cardsY], height);
        var countdownY = RugbyTimerRenderer.calculateCountdownPosition(layout, cardInfo, height);
        RugbyTimerRenderer.renderCountdown(dc, model, width, fonts[:countdownFont], countdownY);
        var stateY = RugbyTimerRenderer.calculateStateY(countdownY, layout, height);
        RugbyTimerRenderer.renderStateText(dc, model, width, fonts[:stateFont], stateY, height);
        var hintY = RugbyTimerRenderer.calculateHintY(stateY, layout[:hintBaseY], height);
        renderHint(dc, width, fonts[:hintFont], hintY);

        RugbyTimerOverlay.renderSpecialOverlay(self, model, dc, width, height);
        // Toast message for non-overlay states (e.g. idle timer adjustment feedback)
        if (!isSpecialOverlayActive() && specialOverlayMessage != null && System.getTimer() < specialOverlayMessageExpiry) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
            dc.drawText(width / 2, height * 0.62, Graphics.FONT_MEDIUM, specialOverlayMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    /**
     * Renders a hint text at the bottom of the screen.
     * @param dc The device context
     * @param width The width of the screen
     * @param hintFont The font to use for the hint
     * @param hintY The Y position of the hint
     */
    function renderHint(dc, width, hintFont, hintY) {
        var hint = "";
        if (model.gameState == STATE_IDLE) {
            hint = loadString(Rez.Strings.Hint_Idle_Adjust);
        } else if (model.gameState == STATE_PLAYING) {
            hint = loadString(Rez.Strings.Hint_Select_Pause);
        } else if (model.gameState == STATE_PAUSED) {
            hint = loadString(Rez.Strings.Hint_Select_Resume);
        }
        if (isLocked) {
            hint = loadString(Rez.Strings.Hint_Locked);
        }
        var hintColor = dimMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE;
        dc.setColor(hintColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, hintY, hintFont, hint, Graphics.TEXT_JUSTIFY_CENTER);
    }

    /**
     * Loads string resources explicitly so the UI never renders raw numeric resource ids.
     * @param resourceId The Rez string identifier
     * @return The resolved display string
     */
    function loadString(resourceId) {
        if (resourceId instanceof Lang.String) {
            return resourceId;
        }
        var value = WatchUi.loadResource(resourceId);
        if (value instanceof Lang.String) {
            return value;
        }
        return "";
    }

    /**
     * This method is called periodically to update the game state and refresh the view.
     */
    function updateGame() as Void {
        model.updateGame();
        WatchUi.requestUpdate();
    }

    /**
     * Helper that displays a short M:SS string for cards while hiding zeros.
     * @param seconds The number of seconds to format
     * @return A formatted string in M:SS format
     */
    function formatShortTime(seconds) {
        if (seconds <= 0) {
            return "--";
        }
        var mins = (seconds.toLong() / 60);
        var secs = (seconds.toLong() % 60);
        return mins.toString() + ":" + secs.format("%02d");
    }

    /**
     * Launches the score dialog stack; respects the locked state.
     */
    function showScoreDialog() {
        if (isLocked) {
            return;
        }
        WatchUi.pushView(new ScoreTeamMenu(), new ScoreTeamDelegate(model), WatchUi.SLIDE_UP);
    }

    /**
     * Launches the card/discipline dialog (swap button assigned externally).
     */
    function showCardDialog() {
        if (isLocked) {
            return;
        }
        WatchUi.pushView(new CardTeamMenu(), new CardTeamDelegate(model as RugbyGameModel), WatchUi.SLIDE_UP);
    }

    /**
     * Lock/unlock the UI so accidental button presses can't change state.
     */
    function toggleLock() {
        isLocked = !isLocked;
        RugbyTimerTiming.triggerLockToggleVibe();
        WatchUi.requestUpdate();
    }

    /**
     * This method is called when the view is hidden.
     */
    function onHide() {
        if (updateTimer != null) {
            updateTimer.stop();
            updateTimer = null;
        }
    }

    /**
     * @return true if the special overlay is active, false otherwise
     */
    function isSpecialOverlayActive() {
        return RugbyTimerOverlay.isSpecialOverlayActive(self, model);
    }

    /**
     * Closes the special timer screen.
     */
    function closeSpecialTimerScreen() {
        RugbyTimerOverlay.closeSpecialTimerScreen(self);
    }

    /**
     * Shows the special timer screen.
     */
    function showSpecialTimerScreen() {
        RugbyTimerOverlay.showSpecialTimerScreen(self, model);
    }

    /**
     * Displays a message on the special overlay.
     * @param text The text to display
     */
    function displaySpecialOverlayMessage(text) {
        RugbyTimerOverlay.displaySpecialOverlayMessage(self, text);
    }
}
