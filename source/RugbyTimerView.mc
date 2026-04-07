using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Timer;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application.Storage;
using Rez.Strings;
using Rez.Drawables;

/**
 * Primary watch view for the live match screen.
 *
 * Purpose: bridge the public game model to the render/timing/overlay helpers
 * and retain view-only state such as lock and overlay visibility.
 */
class RugbyTimerView extends WatchUi.View {
    // The game model
    var model as RugbyGameModel;
    
    // Cached font information
    var cachedFonts;
    // Cached layout information
    var cachedLayout;

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
    // Cached icons (preloaded to avoid loadResource in draw path)
    var cachedLockIcon;
    var cachedPlayIcon;
    var cachedPauseIcon;
    // Last profiler report timestamp
    var lastProfilerReportTime;
    
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
        dimMode = Storage.getValue(STORAGE_KEY_DIM_MODE);
        if (dimMode == null) { dimMode = false; }
        // Preload small bitmaps once at init
        try {
            cachedLockIcon = WatchUi.loadResource(Rez.Drawables.LockIcon) as WatchUi.BitmapResource;
        } catch (ex) { cachedLockIcon = null; }
        try {
            cachedPlayIcon = WatchUi.loadResource(Rez.Drawables.PlayIcon) as WatchUi.BitmapResource;
        } catch (ex) { cachedPlayIcon = null; }
        try {
            cachedPauseIcon = WatchUi.loadResource(Rez.Drawables.PauseIcon) as WatchUi.BitmapResource;
        } catch (ex) { cachedPauseIcon = null; }
        lastProfilerReportTime = 0;
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
        RugbyTimerRenderer.invalidateMainLayoutCache();
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
        RugbyMatchIntegritySupport.reconcileModelState(model);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var renderNow = System.getTimer();

        // Conversion overlays should reopen automatically when a try transitions the
        // model into conversion state, even if that happened while a menu was on top.
        var wasOverlayVisible = specialTimerOverlayVisible == true;
        specialTimerOverlayVisible = RugbyTimerViewSupport.getOverlayVisibility(specialTimerOverlayVisible, model.gameState);
        if (wasOverlayVisible && !specialTimerOverlayVisible) {
            specialOverlayMessage = null;
            specialOverlayMessageExpiry = 0;
        }

        // Use cached fonts and layout
        var fonts = cachedFonts;
        var layout = cachedLayout;

        var labelsDrawn = RugbyTimerRenderer.renderScores(dc, model, width, height, fonts.scoreFont, layout.scoreY);
        RugbyTimerRenderer.renderGameTimer(dc, model, width, fonts.timerFont, layout.gameTimerY, renderNow);
        RugbyTimerRenderer.renderHalfAndTries(dc, model, width, height, fonts.halfFont, fonts.triesFont, layout.halfY, layout.triesY, labelsDrawn);
        RugbyTimerRenderer.renderPlayPauseIndicator(dc, model, width, height, layout.iconY, cachedPlayIcon, cachedPauseIcon);
        if (isLocked) {
            RugbyTimerRenderer.renderLockIndicator(dc, width, height, layout.scoreY, cachedLockIcon);
        }

        var cardInfo = RugbyTimerRenderer.renderCardTimers(dc, model, width, layout.cardsY, height, renderNow);
        var mainContentLayout = RugbyTimerRenderer.getMainContentLayoutCached(dc, model, fonts, layout, cardInfo, height, isLocked);
        RugbyTimerRenderer.renderCountdown(dc, model, width, fonts.countdownFont, mainContentLayout.countdownY, renderNow);
        RugbyTimerRenderer.renderStateText(dc, model, width, fonts.stateFont, mainContentLayout.stateY, height, renderNow);
        renderHint(dc, width, fonts.hintFont, mainContentLayout.hintY, height, mainContentLayout.hintLineGap);

        RugbyTimerOverlay.renderSpecialOverlay(self, model, dc, width, height);
        // Toast message for non-overlay states (e.g. idle timer adjustment feedback)
        var overlayActive = isSpecialOverlayActive() || RugbyTimerViewSupport.isHalftimeBreakActive(model);
        if (RugbyTimerViewSupport.shouldShowToast(overlayActive, specialOverlayMessage, specialOverlayMessageExpiry, System.getTimer())) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
            dc.drawText(width / 2, height * 0.62, Graphics.FONT_MEDIUM, specialOverlayMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }
        // Periodic profiler report (debug only)
        if (Profiler.ENABLED) {
            var now = System.getTimer();
            if (lastProfilerReportTime == null) { lastProfilerReportTime = now; }
            if (now - lastProfilerReportTime > 5000) {
                Profiler.report();
                Profiler.reset();
                lastProfilerReportTime = now;
            }
        }
    }

    /**
     * Renders a hint text at the bottom of the screen.
     * @param dc The device context
     * @param width The width of the screen
     * @param hintFont The font to use for the hint
     * @param hintY The Y position of the hint
     */
    function renderHint(dc, width, hintFont, hintY, height, hintLineGap) {
        var hintColor = dimMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE;
        dc.setColor(hintColor, Graphics.COLOR_TRANSPARENT);
        var hintMode = RugbyTimerViewSupport.getHintMode(isLocked, model.gameState);
        var hintFontHeight = RugbyTimerRenderer.getFontHeightSafe(dc, hintFont, height * 0.04);
        var stackedHintY = height - (hintFontHeight * 2) - hintLineGap - (height * 0.05);
        if (stackedHintY < hintY) {
            stackedHintY = hintY;
        }
        if (hintMode == VIEW_HINT_MODE_LOCKED) {
            dc.drawText(width / 2, hintY, hintFont, loadString(Rez.Strings.Hint_Locked), Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        if (hintMode == VIEW_HINT_MODE_IDLE) {
            dc.drawText(width / 2, stackedHintY, hintFont, loadString(Rez.Strings.Hint_Idle_Adjust), Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, stackedHintY + hintLineGap, hintFont, loadString(Rez.Strings.Hint_Select_Start), Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        if (hintMode == VIEW_HINT_MODE_PLAYING) {
            dc.drawText(width / 2, hintY, hintFont, loadString(Rez.Strings.Hint_Select_Pause), Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        if (hintMode == VIEW_HINT_MODE_HALFTIME) {
            dc.drawText(width / 2, stackedHintY, hintFont, loadString(Rez.Strings.Hint_Halftime_Adjust), Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, stackedHintY + hintLineGap, hintFont, loadString(Rez.Strings.Hint_Select_Half2), Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
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
        if (resourceId == Rez.Strings.Hint_Idle_Adjust) { return "UP/MENU: +1   DOWN: -1"; }
        if (resourceId == Rez.Strings.Hint_Select_Start) { return "SELECT: Start"; }
        if (resourceId == Rez.Strings.Hint_Select_Pause) { return "SELECT: Pause"; }
        if (resourceId == Rez.Strings.Hint_Halftime_Adjust) { return "UP/MENU: +1   DOWN: -1"; }
        if (resourceId == Rez.Strings.Hint_Select_Half2) { return "SELECT: Half 2"; }
        if (resourceId == Rez.Strings.Hint_Locked) { return "LOCKED"; }
        return "";
    }

    /**
     * This method is called periodically to update the game state and refresh the view.
     */
    function updateGame() as Void {
        model.updateGame();
        var runtimeNotice = model.consumeRuntimeNotice();
        if (runtimeNotice != null && runtimeNotice.channel == RUGBY_NOTICE_CHANNEL_TOAST) {
            displaySpecialOverlayMessage(runtimeNotice.message);
        }
        WatchUi.requestUpdate();
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
