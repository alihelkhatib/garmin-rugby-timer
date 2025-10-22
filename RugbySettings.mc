using Toybox.WatchUi;
using Toybox.Application.Storage;

class RugbySettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Rugby Settings"});
        
        var is7s = Storage.getValue("rugby7s");
        if (is7s == null) {
            is7s = false;
        }
        
        var gameType = is7s ? "Rugby 7s" : "Rugby 15s";
        addItem(new WatchUi.MenuItem("Game Type", gameType, :game_type, null));
        addItem(new WatchUi.MenuItem("Reset Scores", null, :reset, null));
    }
}

class RugbySettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        if (item.getId() == :game_type) {
            var is7s = Storage.getValue("rugby7s");
            if (is7s == null) {
                is7s = false;
            }
            is7s = !is7s;
            Storage.setValue("rugby7s", is7s);
            
            // Update menu item
            var gameType = is7s ? "Rugby 7s" : "Rugby 15s";
            item.setSubLabel(gameType);
            WatchUi.requestUpdate();
        } else if (item.getId() == :reset) {
            var app = Application.getApp();
            if (app.rugbyView != null) {
                app.rugbyView.homeScore = 0;
                app.rugbyView.awayScore = 0;
                app.rugbyView.halfNumber = 1;
                app.rugbyView.elapsedTime = 0;
                app.rugbyView.gameState = STATE_IDLE;
                WatchUi.requestUpdate();
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}