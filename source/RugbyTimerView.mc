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
    var mFonts as Dictionary;
    // Cached layout information
    var mLayout as Dictionary;

    // A flag to ensure the game type prompt is shown only once
    var promptedGameType as Boolean;
    // A boolean indicating if the screen is locked
    var isLocked as Boolean;
    // A boolean indicating if the screen is in dim mode
    var dimMode as Boolean;
    // The timestamp of the last user action
    var lastActionTs as Number;
    // A boolean indicating if the special timer overlay is visible
    var specialTimerOverlayVisible as Boolean;
    // The message to be displayed on the special overlay
    var specialOverlayMessage as String or Null;
    // The expiry timestamp for the special overlay message
    var specialOverlayMessageExpiry as Number;
    
    // The timer for updating the game state
    var updateTimer as Timer.Timer or Null;
    
    /**
     * Initializes the view.
     * @param m The game model
     */
    function initialize(m as RugbyGameModel) {
        View.initialize();
        model = m;
        
        promptedGameType = false;
        isLocked = false;
        lastActionTs = 0;
        specialTimerOverlayVisible = false;
        specialOverlayMessage = null;
        specialOverlayMessageExpiry = 0;
        var dimModeValue = Storage.getValue("dimMode") as Boolean or Null;
        if (dimModeValue == null) { dimMode = false; } else { dimMode = dimModeValue; }
    }

    /**
     * This method is called when the view is laid out.
     * @param dc The device context
     */
    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        // Calculate and cache fonts and layout once
        mFonts = RugbyTimerRenderer.chooseFonts(dc.getWidth());
        mLayout = RugbyTimerRenderer.calculateLayout(dc.getHeight());
    }

    /**
     * This method is called when the view is shown.
     */
    function onShow() as Void {
        if (updateTimer == null) {
            updateTimer = new Timer.Timer();
            updateTimer.start(method(:updateGame), 100, true);
        }
        
        if (!promptedGameType && model.gameState == STATE_IDLE) {
            promptedGameType = true;
            showGameTypePrompt();
        }
    }

    /**
     * Simple debounce for adjustments/quick actions.
     * Simple debounce gate to prevent rapid repeated actions from hardware buttons.
     * @return true if the action is allowed, false otherwise
     */
    function isActionAllowed() as Boolean {
        var now = System.getTimer() as Number;
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
    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth() as Number;
        var height = dc.getHeight() as Number;

        // Use cached fonts and layout
        var fonts = mFonts as Dictionary;
        var layout = mLayout as Dictionary;

        RugbyTimerRenderer.renderScores(dc, model as RugbyGameModel, width, fonts[:scoreFont] as FontResource, layout[:scoreY] as Number);
        RugbyTimerRenderer.renderGameTimer(dc, model as RugbyGameModel, width, fonts[:timerFont] as FontResource, layout[:gameTimerY] as Number);
        RugbyTimerRenderer.renderHalfAndTries(dc, model as RugbyGameModel, width, fonts[:halfFont] as FontResource, fonts[:triesFont] as FontResource, layout[:halfY] as Number, layout[:triesY] as Number);
        if (isLocked) {
            RugbyTimerRenderer.renderLockIndicator(dc, self as RugbyTimerView, width, fonts[:halfFont] as FontResource, layout[:scoreY] as Number);
        }

        var cardInfo = RugbyTimerRenderer.renderCardTimers(dc, model as RugbyGameModel, width, layout[:cardsY] as Number, height) as Dictionary;
        var countdownY = RugbyTimerRenderer.calculateCountdownPosition(layout, cardInfo, height) as Number;
        RugbyTimerRenderer.renderCountdown(dc, model as RugbyGameModel, width, fonts[:countdownFont] as FontResource, countdownY);
        var stateY = RugbyTimerRenderer.calculateStateY(countdownY, layout, height) as Number;
        RugbyTimerRenderer.renderStateText(dc, model as RugbyGameModel, width, fonts[:stateFont] as FontResource, stateY, height);
        var hintY = RugbyTimerRenderer.calculateHintY(stateY, layout[:hintBaseY] as Number, height) as Number;
        renderHint(dc, width, fonts[:hintFont] as FontResource, hintY);

        RugbyTimerOverlay.renderSpecialOverlay(self as RugbyTimerView, model as RugbyGameModel, dc, width, height);
    }

    /**
     * Renders a hint text at the bottom of the screen.
     * @param dc The device context
     * @param width The width of the screen
     * @param hintFont The font to use for the hint
     * @param hintY The Y position of the hint
     */
    function renderHint(dc as Graphics.Dc, width as Number, hintFont as FontResource, hintY as Number) as Void {
        var hint = "";
        if (model.gameState == STATE_IDLE) {
            hint = Rez.Strings.Hint_Select_Start;
        } else if (model.gameState == STATE_PLAYING) {
            hint = Rez.Strings.Hint_Select_Pause;
        } else if (model.gameState == STATE_PAUSED) {
            hint = Rez.Strings.Hint_Select_Resume;
        }
        if (isLocked) {
            hint = Rez.Strings.Hint_Locked;
        }
        var hintColor = dimMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE;
        dc.setColor(hintColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, hintY, hintFont, hint, Graphics.TEXT_JUSTIFY_CENTER);
    }

    /**
     * This method is called periodically to update the game state and refresh the view.
     */
    function updateGame() as Void {
        (model as RugbyGameModel).updateGame();
        WatchUi.requestUpdate();
    }

    /**
     * Helper that displays a short M:SS string for cards while hiding zeros.
     * @param seconds The number of seconds to format
     * @return A formatted string in M:SS format
     */
    function formatShortTime(seconds as Number) as String {
        if (seconds <= 0) {
            return "--";
        }
        var mins = (seconds.toLong() / 60);
        var secs = (seconds.toLong() % 60);
        return mins.toString() + ":" + secs.format("%02d");
    }

    /**
     * Presents the menu asking whether the match is 7s or 15s.
     */
    function showGameTypePrompt() as Void {
        WatchUi.pushView(new GameTypeMenu(), new GameTypePromptDelegate(model as RugbyGameModel), WatchUi.SLIDE_UP);
    }

    /**
     * Launches the score dialog stack; respects the locked state.
     */
    function showScoreDialog() as Void {
        if (isLocked) {
            return;
        }
        WatchUi.pushView(new ScoreTeamMenu(), new ScoreTeamDelegate(model as RugbyGameModel), WatchUi.SLIDE_UP);
    }

    /**
     * Launches the card/discipline dialog (swap button assigned externally).
     */
    function showCardDialog() as Void {
        if (isLocked) {
            return;
        }
        WatchUi.pushView(new CardTeamMenu(), new CardTypeDelegate(model as RugbyGameModel), WatchUi.SLIDE_UP);
    }

    /**
     * Lock/unlock the UI so accidental button presses can't change state.
     */
    function toggleLock() as Void {
        isLocked = !isLocked;
        WatchUi.requestUpdate();
    }

    /**
     * This method is called when the view is hidden.
     */
    function onHide() as Void {
        if (updateTimer != null) {
            updateTimer.stop();
            updateTimer = null;
        }
    }

    /**
     * @return true if the special overlay is active, false otherwise
     */
    function isSpecialOverlayActive() as Boolean {
        return RugbyTimerOverlay.isSpecialOverlayActive(self as RugbyTimerView, model as RugbyGameModel);
    }

    /**
     * Closes the special timer screen.
     */
    function closeSpecialTimerScreen() as Void {
        RugbyTimerOverlay.closeSpecialTimerScreen(self as RugbyTimerView);
    }

    /**
     * Shows the special timer screen.
     */
    function showSpecialTimerScreen() as Void {
        RugbyTimerOverlay.showSpecialTimerScreen(self as RugbyTimerView, model as RugbyGameModel);
    }

    /**
     * Displays a message on the special overlay.
     * @param text The text to display
     */
    function displaySpecialOverlayMessage(text as String) as Void {
        RugbyTimerOverlay.displaySpecialOverlayMessage(self as RugbyTimerView, text);
    }
}
