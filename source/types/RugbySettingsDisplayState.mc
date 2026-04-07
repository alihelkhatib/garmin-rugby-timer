/**
 * Typed view-model for the Rugby Settings root menu.
 *
 * Purpose: keep the displayed subtitle labels in one testable structure so the
 * menu can rebuild from the live model without duplicating formatting rules.
 */
class RugbySettingsDisplayState {
    var matchFormatLabel;
    var conversionLabel;
    var penaltyLabel;
    var useConversionLabel;
    var usePenaltyLabel;
    var teamLabelsLabel;
    var lockOnStartLabel;
    var dimThemeLabel;

    static function create(matchFormatLabel, conversionLabel, penaltyLabel, useConversionLabel, usePenaltyLabel, teamLabelsLabel, lockOnStartLabel, dimThemeLabel) {
        var state = new RugbySettingsDisplayState();
        state.matchFormatLabel = matchFormatLabel;
        state.conversionLabel = conversionLabel;
        state.penaltyLabel = penaltyLabel;
        state.useConversionLabel = useConversionLabel;
        state.usePenaltyLabel = usePenaltyLabel;
        state.teamLabelsLabel = teamLabelsLabel;
        state.lockOnStartLabel = lockOnStartLabel;
        state.dimThemeLabel = dimThemeLabel;
        return state;
    }
}
