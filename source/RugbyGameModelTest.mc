using Toybox.System;
using Toybox.Lang;
using Toybox.Test;
using Toybox.Application;

// Assuming STATE_IDLE etc. are globally defined or imported
// For simplicity, let's redefine them for the test scope if not global
enum {
    STATE_IDLE,
    STATE_PLAYING,
    STATE_PAUSED,
    STATE_CONVERSION,
    STATE_PENALTY,
    STATE_KICKOFF,
    STATE_HALFTIME,
    STATE_ENDED
}

(:test)
function testRugbyGameModelInitialize(logger) {
    var model = new RugbyGameModel();

    Test.assertEqual(model.gameState, STATE_IDLE, "Initial game state should be IDLE");
    Test.assertEqual(model.homeScore, 0, "Initial home score should be 0");
    Test.assertEqual(model.awayScore, 0, "Initial away score should be 0");
    Test.assertEqual(model.halfNumber, 1, "Initial half number should be 1");
    Test.assertEqual(model.gameTime, 0, "Initial game time should be 0");
    Test.assertEqual(model.elapsedTime, 0, "Initial elapsed time should be 0");
    Test.assertEqual(model.countdownSeconds, 0, "Initial countdown seconds should be 0");
    Test.assertNotNull(model.yellowHomeTimes, "Yellow home times should be initialized");
    Test.assertNotNull(model.yellowAwayTimes, "Yellow away times should be initialized");
    Test.assertEqual(model.yellowHomeTimes.size(), 0, "Yellow home times should be empty");
    Test.assertEqual(model.yellowAwayTimes.size(), 0, "Yellow away times should be empty");
    Test.assertEqual(model.yellowHomeLabelCounter, 0, "Yellow home label counter should be 0");
    Test.assertEqual(model.yellowAwayLabelCounter, 0, "Yellow away label counter should be 0");
    Test.assertEqual(model.redHome, 0, "Red home should be 0");
    Test.assertEqual(model.redAway, 0, "Red away should be 0");
    Test.assertEqual(model.redHomePermanent, false, "Red home permanent should be false");
    Test.assertEqual(model.redAwayPermanent, false, "Red away permanent should be false");
    Test.assertEqual(model.yellowHomeTotal, 0, "Yellow home total should be 0");
    Test.assertEqual(model.yellowAwayTotal, 0, "Yellow away total should be 0");
    Test.assertEqual(model.redHomeTotal, 0, "Red home total should be 0");
    Test.assertEqual(model.redAwayTotal, 0, "Red away total should be 0");

    return true;
}

(:test)
function testRugbyGameModelStartGame(logger) {
    var model = new RugbyGameModel();
    // Assuming STATE_IDLE is 0
    model.gameState = STATE_IDLE; // Ensure initial state is IDLE for testing startGame

    model.startGame();

    Test.assertEqual(model.gameState, STATE_PLAYING, "Game state should be PLAYING after startGame");
    Test.assertNotNull(model.gameStartTime, "Game start time should be set");
    Test.assertNotNull(model.lastUpdate, "Last update time should be set");
    Test.assertEqual(model.elapsedTime, 0, "Elapsed time should be 0 at start");
    Test.assertEqual(model.gameTime, 0, "Game time should be 0 at start");

    // Additional checks for properties that might be influenced by start
    Test.assertEqual(model.countdownSeconds, 0, "Countdown seconds should be 0 after startGame");
    // countdownRemaining should be reset to countdownTimer
    Test.assertEqual(model.countdownRemaining, model.countdownTimer, "Countdown remaining should be reset to countdown timer");
    Test.assertEqual(model.thirtySecondAlerted, false, "Thirty second alerted should be false");
    
    // As startRecording creates a session, we can check if it's not null
    Test.assertNotNull(model.session, "Activity session should be created");

    return true;
}

(:test)
function testRugbyGameModelRecordTry(logger) {
    var model = new RugbyGameModel();
    model.gameState = STATE_PLAYING; // Must be playing to record a try with conversion

    model.recordTry(true); // Home team try

    Test.assertEqual(model.homeScore, 5, "Home score should be 5 after try");
    Test.assertEqual(model.homeTries, 1, "Home tries should be 1 after try");
    Test.assertEqual(model.lastEvents.size(), 1, "Last events should contain one entry");
    Test.assertEqual(model.lastEvents[0][:type], :try, "Last event type should be :try");
    Test.assertEqual(model.gameState, STATE_CONVERSION, "Game state should be CONVERSION after try");
    Test.assertNotNull(model.conversionTeam, "Conversion team should be set");
    Test.assertEqual(model.conversionTeam, true, "Conversion team should be home");
    Test.assertTrue(model.countdownSeconds > 0, "Conversion countdown should be started");

    model = new RugbyGameModel();
    model.gameState = STATE_PLAYING; // Must be playing to record a try with conversion
    model.recordTry(false); // Away team try

    Test.assertEqual(model.awayScore, 5, "Away score should be 5 after try");
    Test.assertEqual(model.awayTries, 1, "Away tries should be 1 after try");
    Test.assertEqual(model.lastEvents.size(), 1, "Last events should contain one entry");
    Test.assertEqual(model.lastEvents[0][:type], :try, "Last event type should be :try");
    Test.assertEqual(model.gameState, STATE_CONVERSION, "Game state should be CONVERSION after try");
    Test.assertNotNull(model.conversionTeam, "Conversion team should be set");
    Test.assertEqual(model.conversionTeam, false, "Conversion team should be away");

    return true;
}

(:test)
function testRugbyGameModelResetGame(logger) {
    var model = new RugbyGameModel();
    // Set some state to be reset
    model.homeScore = 10;
    model.awayScore = 7;
    model.gameState = STATE_PLAYING;
    model.halfNumber = 2;
    model.gameTime = 100;
    model.elapsedTime = 200;
    model.yellowHomeTimes.add({"remaining" => 60, "vibeTriggered" => false, "label" => "Y1", "cardId" => 1});
    model.yellowHomeTotal = 1;
    model.lastEvents.add({:type => :try, :home => true});

    model.resetGame();

    Test.assertEqual(model.gameState, STATE_IDLE, "Game state should be IDLE after reset");
    Test.assertEqual(model.homeScore, 0, "Home score should be 0 after reset");
    Test.assertEqual(model.awayScore, 0, "Away score should be 0 after reset");
    Test.assertEqual(model.homeTries, 0, "Home tries should be 0 after reset");
    Test.assertEqual(model.awayTries, 0, "Away tries should be 0 after reset");
    Test.assertEqual(model.halfNumber, 1, "Half number should be 1 after reset");
    Test.assertEqual(model.gameTime, 0, "Game time should be 0 after reset");
    Test.assertEqual(model.elapsedTime, 0, "Elapsed time should be 0 after reset");
    Test.assertEqual(model.countdownSeconds, 0, "Countdown seconds should be 0 after reset");
    Test.assertNull(model.gameStartTime, "Game start time should be null after reset");
    Test.assertNull(model.lastUpdate, "Last update should be null after reset");
    Test.assertEqual(model.lastEvents.size(), 0, "Last events should be empty after reset");
    Test.assertEqual(model.yellowHomeTimes.size(), 0, "Yellow home times should be empty after reset");
    Test.assertEqual(model.yellowHomeTotal, 0, "Yellow home total should be 0 after reset");
    Test.assertNull(model.conversionTeam, "Conversion team should be null after reset");
    // Ensure stopRecording was called, setting session to null
    Test.assertNull(model.session, "Activity session should be null after reset");

    return true;
}
