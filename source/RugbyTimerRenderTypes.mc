/*
Small typed helpers shared by the card and presentation layers.

Purpose: keep lightweight value carriers available where they clarify intent,
without retaining the old renderer geometry model.
*/

class RugbyCardSlotPresentation {
    var label;
    var value;
    var color;
    var visible;

    static function create(labelValue, valueText, colorValue, visibleValue) {
        var slot = new RugbyCardSlotPresentation();
        slot.label = labelValue;
        slot.value = valueText;
        slot.color = colorValue;
        slot.visible = visibleValue == true;
        return slot;
    }
}

class RugbyTimerUpdateResult {
    var timers;
    var expired;

    static function create(timers, expired) {
        var result = new RugbyTimerUpdateResult();
        result.timers = timers;
        result.expired = expired == true;
        return result;
    }
}
