using Toybox.System;
using Toybox.Lang;
using Toybox.Test;

/*
Advanced card-timer tests.

Purpose: exercise the card timer code paths that have changed frequently and
ensure regressions do not reappear. Each test includes a short comment
explaining what it verifies so the test intent is traceable.
*/

(:test)
function test_yellow_multiple_ordering_and_numbering(logger as Test.Logger) as Lang.Boolean {
    // Purpose: multiple yellow cards for a team should append and carry incrementing labels per-team.
    var model = new RugbyGameModel();
    model.initialize();

    // Reset relevant collections/counters to ensure deterministic behavior.
    model.yellowHomeTimes = [];
    model.yellowAwayTimes = [];
    model.yellowHomeLabelCounter = 0;
    model.yellowAwayLabelCounter = 0;

    // Use a fixed suspension clock so entries have predictable startTime.
    model.suspensionTime = 100;

    // Issue cards: two for home, one for away.
    model.recordYellowCard(true);
    model.recordYellowCard(true);
    model.recordYellowCard(false);

    // Expect two home entries, one away entry.
    if (model.yellowHomeTimes.size() != 2) {
        logger.error("yellowHomeTimes.size()!=2 -> " + model.yellowHomeTimes.size().toString());
        return false;
    }
    if (model.yellowAwayTimes.size() != 1) {
        logger.error("yellowAwayTimes.size()!=1 -> " + model.yellowAwayTimes.size().toString());
        return false;
    }

    // Labels should increment per-team. First home label Y1, second Y2; away first label Y1.
    var homeTimes = model.yellowHomeTimes;
    var awayTimes = model.yellowAwayTimes;
    var h0 = CardEntry.fromDict(homeTimes.remove(0));
    var h1 = CardEntry.fromDict(homeTimes.remove(0));
    var a0 = CardEntry.fromDict(awayTimes.remove(0));
    if (h0 == null || h1 == null || a0 == null) { logger.error("yellow entries missing"); return false; }
    logger.debug("home labels: " + h0.label + ", " + h1.label + " away: " + a0.label);
    return (h0.label == "Y1") && (h1.label == "Y2") && (a0.label == "Y1");
}

(:test)
function test_red_numbering_and_timed_entries(logger as Test.Logger) as Lang.Boolean {
    // Purpose: in non-7s rules (timed red cards) red entries should be created and numbered per-team.
    var model = new RugbyGameModel();
    model.initialize();

    model.redHomeTimes = [];
    model.redAwayTimes = [];
    model.redHomeLabelCounter = 0;
    model.redAwayLabelCounter = 0;

    // Ensure 15s-style rules (timed red cards)
    model.is7s = false;
    model.suspensionTime = 200;

    // One red for home and one for away
    model.recordRedCard(true);
    model.recordRedCard(false);

    if (model.redHomeTimes.size() != 1) {
        logger.error("expected 1 redHomeTimes entry, got " + model.redHomeTimes.size().toString());
        return false;
    }
    if (model.redAwayTimes.size() != 1) {
        logger.error("expected 1 redAwayTimes entry, got " + model.redAwayTimes.size().toString());
        return false;
    }

    var redHomeTimes = model.redHomeTimes;
    var redAwayTimes = model.redAwayTimes;
    var rh = CardEntry.fromDict(redHomeTimes.remove(0));
    var ra = CardEntry.fromDict(redAwayTimes.remove(0));
    if (rh == null || ra == null) { logger.error("red entries missing"); return false; }
    logger.debug("red labels home/away: " + rh.label + ", " + ra.label);

    // Add another home red and expect label R2 for the second entry.
    model.recordRedCard(true);
    if (model.redHomeTimes.size() != 2) { return false; }
    var rh2 = CardEntry.fromDict(redHomeTimes.remove(0));
    if (rh2 == null) { logger.error("second red entry missing"); return false; }
    return (rh.label == "R1") && (ra.label == "R1") && (rh2.label == "R2");
}

(:test)
function test_yellow_timer_sync_with_suspension(logger as Test.Logger) as Lang.Boolean {
    // Purpose: a yellow card's remaining time must decrease as the model.suspensionTime advances.
    var model = new RugbyGameModel();
    model.initialize();

    model.yellowHomeTimes = [];
    model.yellowHomeLabelCounter = 0;
    model.suspensionTime = 100;

    model.recordYellowCard(true);
    var yellowTimes = model.yellowHomeTimes;
    var entry = CardEntry.fromDict(yellowTimes.remove(0));
    var before = entry.remaining as Lang.Number;

    // Advance suspension clock by 30s and update timers using the same clock units.
    model.suspensionTime = 130;
    var out = RugbyTimerCards.updateYellowTimers(model, model.yellowHomeTimes, model.suspensionTime);
    var timers = out.timers as Lang.Array;
    if (timers.size() != 1) { logger.error("unexpected timers size"); return false; }
    var updatedEntry = CardEntry.fromDict(timers[0]);
    var after = updatedEntry.remaining as Lang.Number;
    logger.debug("remaining before=" + before.toString() + " after=" + after.toString());

    // Allow 1-second rounding tolerance when comparing to integer seconds.
    var diff = before.toLong() - after.toLong();
    return (diff >= 29 && diff <= 31);
}

(:test)
function test_red_permanent_in_7s_sets_flag_and_increments_counter(logger as Test.Logger) as Lang.Boolean {
    // Purpose: under 7s rules a red card should mark the team as permanently reduced and still increment the label counter.
    var model = new RugbyGameModel();
    model.initialize();

    model.redHomeTimes = [];
    model.redHomeLabelCounter = 0;
    model.redHomePermanent = false;
    model.is7s = true;
    model.suspensionTime = 500;

    model.recordRedCard(true);

    if (!model.redHomePermanent) { logger.error("redHomePermanent not set"); return false; }
    if (model.redHomeLabelCounter != 1) { logger.error("unexpected redHomeLabelCounter=" + model.redHomeLabelCounter.toString()); return false; }
    // No timed red entry should be created for permanent red.
    if (model.redHomeTimes.size() != 0) { logger.error("unexpected timed red entries found"); return false; }
    return true;
}
