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
 * Purpose: bridge the public game model to the XML-owned layouts while keeping
 * view-only state such as lock and overlay visibility here.
 */
class RugbyTimerView extends WatchUi.View {
    var model as RugbyGameModel;
    var currentLayoutId;
    var currentFamily;
    var drawableCache;
    var isLocked;
    var dimMode;
    var showIdleHints;
    var lastActionTs;
    var specialTimerOverlayVisible;
    var specialOverlayMessage;
    var specialOverlayMessageExpiry;
    var cachedLockIcon;
    var cachedPlayIcon;
    var cachedPauseIcon;
    var lastProfilerReportTime;
    var updateTimer;

    function initialize(m) {
        View.initialize();
        model = m;
        currentLayoutId = null;
        currentFamily = null;
        drawableCache = {};
        isLocked = false;
        lastActionTs = 0;
        specialTimerOverlayVisible = false;
        specialOverlayMessage = null;
        specialOverlayMessageExpiry = 0;
        try {
            cachedLockIcon = WatchUi.loadResource(Rez.Drawables.LockIcon) as WatchUi.BitmapResource;
        } catch (ex) { cachedLockIcon = null; }
        try {
            cachedPlayIcon = WatchUi.loadResource(Rez.Drawables.PlayIcon) as WatchUi.BitmapResource;
        } catch (ex2) { cachedPlayIcon = null; }
        try {
            cachedPauseIcon = WatchUi.loadResource(Rez.Drawables.PauseIcon) as WatchUi.BitmapResource;
        } catch (ex3) { cachedPauseIcon = null; }
        dimMode = Storage.getValue(STORAGE_KEY_DIM_MODE);
        if (dimMode == null) { dimMode = false; }
        showIdleHints = RugbySettingsSupport.getStoredFlag(Storage.getValue(STORAGE_KEY_SHOW_IDLE_HINTS), true);
        lastProfilerReportTime = 0;
    }

    function onLayout(dc) {
        ensureLayout(dc);
    }

    function onShow() {
        if (updateTimer == null) {
            updateTimer = new Timer.Timer();
            updateTimer.start(method(:updateGame), 100, true);
        }
    }

    function isActionAllowed() {
        var now = System.getTimer();
        if (lastActionTs == null || now - lastActionTs > 300) {
            lastActionTs = now;
            return true;
        }
        return false;
    }

    function onUpdate(dc) {
        syncOverlayVisibility();
        ensureLayout(dc);
        bindCurrentLayout();
        View.onUpdate(dc);
        renderMainIcons(dc);

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

    function syncOverlayVisibility() {
        if (model.gameState == STATE_CONVERSION && !specialTimerOverlayVisible) {
            specialTimerOverlayVisible = true;
        } else if (specialTimerOverlayVisible && model.gameState != STATE_CONVERSION && model.gameState != STATE_PENALTY) {
            specialTimerOverlayVisible = false;
        }
    }

    function ensureLayout(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var family = RugbyLayoutSupport.getFamily(width, height);
        var useOverlayLayout = RugbyTimerOverlay.isSpecialOverlayActive(self, model);
        var desiredLayoutId = RugbyLayoutSupport.getLayoutId(family, useOverlayLayout);
        if (desiredLayoutId == currentLayoutId) {
            currentFamily = family;
            return;
        }

        currentFamily = family;
        currentLayoutId = RugbyLayoutSupport.applyLayout(self, dc, width, height, useOverlayLayout);
        cacheCurrentDrawables();
    }

    function cacheCurrentDrawables() {
        drawableCache = {};
        var ids = [
            "ElapsedTimer",
            "HomeLabel",
            "AwayLabel",
            "HomeScore",
            "AwayScore",
            "HalfText",
            "HomeTries",
            "AwayTries",
            "HomeCardLabel",
            "HomeCardValue",
            "AwayCardLabel",
            "AwayCardValue",
            "Countdown",
            "StateLine1",
            "StateLine2",
            "HintLine1",
            "HintLine2",
            "StatusMessage",
            "OverlayMainCountdown",
            "OverlayStateLabel",
            "OverlayCountdown",
            "OverlayHint"
        ];
        for (var i = 0; i < ids.size(); i = i + 1) {
            var id = ids[i];
            var drawable = null;
            try {
                drawable = findDrawableById(id);
            } catch (ex) {
                drawable = null;
            }
            drawableCache[id] = drawable;
        }
    }

    function bindCurrentLayout() {
        if (RugbyLayoutSupport.isOverlayLayout(currentLayoutId)) {
            bindOverlayLayout();
            return;
        }
        bindMainLayout();
    }

    function bindMainLayout() {
        setTextDrawable("ElapsedTimer", RugbyTimerRenderer.getElapsedTimerText(model), true, Graphics.COLOR_LT_GRAY);
        setTextDrawable("HomeLabel", "HOME", true, Graphics.COLOR_BLUE);
        setTextDrawable("AwayLabel", "AWAY", true, Graphics.COLOR_YELLOW);
        setTextDrawable("HomeScore", model.homeScore.toString(), true, Graphics.COLOR_WHITE);
        setTextDrawable("AwayScore", model.awayScore.toString(), true, Graphics.COLOR_WHITE);
        setTextDrawable("HalfText", RugbyTimerRenderer.getHalfText(model), true, Graphics.COLOR_WHITE);

        var showTries = RugbyTimerRenderer.shouldShowTries(currentFamily);
        setTextDrawable("HomeTries", RugbyTimerRenderer.getHomeTriesText(model), showTries, Graphics.COLOR_WHITE);
        setTextDrawable("AwayTries", RugbyTimerRenderer.getAwayTriesText(model), showTries, Graphics.COLOR_WHITE);

        var homeCard = RugbyTimerRenderer.getTeamCardPresentation(
            model,
            model.yellowHomeTimes,
            model.redHomeTimes,
            model.redHomePermanent,
            model.redHomeLabelCounter
        );
        var awayCard = RugbyTimerRenderer.getTeamCardPresentation(
            model,
            model.yellowAwayTimes,
            model.redAwayTimes,
            model.redAwayPermanent,
            model.redAwayLabelCounter
        );
        setTextDrawable("HomeCardLabel", homeCard.label, homeCard.visible, homeCard.color);
        setTextDrawable("HomeCardValue", homeCard.value, homeCard.visible, homeCard.color);
        setTextDrawable("AwayCardLabel", awayCard.label, awayCard.visible, awayCard.color);
        setTextDrawable("AwayCardValue", awayCard.value, awayCard.visible, awayCard.color);

        setTextDrawable("Countdown", RugbyTimerRenderer.getCountdownText(model), true, Graphics.COLOR_WHITE);

        var stateColor = RugbyTimerRenderer.getMainStateColor(model);
        var stateLine1 = RugbyTimerRenderer.getMainStateLine1(model);
        var stateLine2 = RugbyTimerRenderer.getMainStateLine2(model);
        setTextDrawable("StateLine1", stateLine1, stateLine1.length() > 0, stateColor);
        setTextDrawable("StateLine2", stateLine2, stateLine2.length() > 0, stateColor);

        var hintLines = getMainHintLines();
        var hintColor = dimMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE;
        setTextDrawable("HintLine1", hintLines[0], hintLines[0].length() > 0, hintColor);
        setTextDrawable("HintLine2", hintLines[1], hintLines[1].length() > 0, hintColor);

        var showStatusMessage = specialOverlayMessage != null && System.getTimer() < specialOverlayMessageExpiry;
        setTextDrawable("StatusMessage", showStatusMessage ? specialOverlayMessage : "", showStatusMessage, Graphics.COLOR_YELLOW);
    }

    function bindOverlayLayout() {
        setTextDrawable("OverlayMainCountdown", RugbyTimerOverlay.getOverlayMainCountdownText(model), true, Graphics.COLOR_WHITE);
        setTextDrawable("OverlayStateLabel", RugbyTimerOverlay.getSpecialStateLabel(model), true, RugbyTimerOverlay.getSpecialStateColor(model));
        setTextDrawable("OverlayCountdown", RugbyTimerOverlay.getOverlayCountdownText(model), true, RugbyTimerOverlay.getSpecialStateColor(model));
        var hint = RugbyTimerOverlay.getSpecialOverlayHint(model);
        setTextDrawable("OverlayHint", hint, hint.length() > 0, Graphics.COLOR_LT_GRAY);

        var showStatusMessage = specialOverlayMessage != null && System.getTimer() < specialOverlayMessageExpiry;
        setTextDrawable("StatusMessage", showStatusMessage ? specialOverlayMessage : "", showStatusMessage, Graphics.COLOR_LT_GRAY);
    }

    function getMainHintLines() {
        var hintMode = RugbyTimerRenderer.getHintMode(model.gameState, isLocked, showIdleHints);
        if (hintMode == "locked") {
            return [loadString(Rez.Strings.Hint_Locked), ""];
        }
        if (hintMode == "idle") {
            return [
                loadString(Rez.Strings.Hint_Idle_Adjust),
                loadString(Rez.Strings.Hint_Select_Start)
            ];
        }
        return ["", ""];
    }

    function setTextDrawable(id, text, visible, color) {
        var drawable = getCachedDrawable(id);
        if (drawable == null) {
            return;
        }
        var safeText = text;
        if (!(safeText instanceof Lang.String)) {
            safeText = "";
        }
        try {
            drawable.setText(safeText);
        } catch (ex) {
        }
        try {
            drawable.setColor(color);
        } catch (ex2) {
        }
        try {
            drawable.setVisible(visible == true);
        } catch (ex3) {
        }
    }

    function renderMainIcons(dc) {
        if (RugbyLayoutSupport.isOverlayLayout(currentLayoutId) || !RugbyTimerRenderer.shouldShowIcons(currentFamily)) {
            return;
        }
        var width = dc.getWidth();
        var height = dc.getHeight();
        var iconY = height * (currentFamily == "rect" ? 0.05 : 0.07);
        var playX = width * (currentFamily == "rect" ? 0.05 : 0.11);
        var lockTargetX = width * (currentFamily == "rect" ? 0.90 : 0.83);
        var playIcon = cachedPlayIcon;
        if (playIcon != null) {
            dc.drawBitmap(playX, iconY, playIcon);
        }
        if (!isLocked || cachedLockIcon == null) {
            return;
        }
        var lockX = lockTargetX;
        try {
            lockX = lockTargetX - cachedLockIcon.getWidth();
        } catch (ex) {
        }
        dc.drawBitmap(lockX, iconY, cachedLockIcon);
    }

    function getCachedDrawable(id) {
        if (drawableCache == null) {
            return null;
        }
        return drawableCache[id];
    }

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

    function updateGame() as Void {
        model.updateGame();
        var statusMessage = model.consumeStatusMessage();
        if (statusMessage != null) {
            displaySpecialOverlayMessage(statusMessage);
        }
        WatchUi.requestUpdate();
    }

    function formatShortTime(seconds) {
        if (seconds <= 0) {
            return "--";
        }
        var mins = (seconds.toLong() / 60);
        var secs = (seconds.toLong() % 60);
        return mins.toString() + ":" + secs.format("%02d");
    }

    function showScoreDialog() {
        if (isLocked) {
            return;
        }
        WatchUi.pushView(new ScoreTeamMenu(), new ScoreTeamDelegate(model), WatchUi.SLIDE_UP);
    }

    function showCardDialog() {
        if (isLocked) {
            return;
        }
        WatchUi.pushView(new CardTeamMenu(), new CardTeamDelegate(model as RugbyGameModel), WatchUi.SLIDE_UP);
    }

    function toggleLock() {
        isLocked = !isLocked;
        RugbyTimerTiming.triggerLockToggleVibe();
        WatchUi.requestUpdate();
    }

    function onHide() {
        if (updateTimer != null) {
            updateTimer.stop();
            updateTimer = null;
        }
    }

    function isSpecialOverlayActive() {
        return RugbyTimerOverlay.isSpecialOverlayActive(self, model);
    }

    function closeSpecialTimerScreen() {
        RugbyTimerOverlay.closeSpecialTimerScreen(self);
    }

    function showSpecialTimerScreen() {
        RugbyTimerOverlay.showSpecialTimerScreen(self, model);
    }

    function displaySpecialOverlayMessage(text) {
        RugbyTimerOverlay.displaySpecialOverlayMessage(self, text);
    }
}
