using Toybox.Application.Storage;

/*
Shared test helpers for the Monkey C unit-test suite.

Purpose: provide common storage cleanup and fixture helpers so individual test
files can focus on behavior instead of repeated setup code.
*/
function clearCustomStorage() {
    Storage.setValue(STORAGE_KEY_CUSTOM_PROFILE_LABEL, null);
    Storage.setValue(STORAGE_KEY_CUSTOM_HALF_DURATION, null);
    Storage.setValue(STORAGE_KEY_CUSTOM_CONVERSION_TIME, null);
    Storage.setValue(STORAGE_KEY_CUSTOM_KICKOFF_TIME, null);
    Storage.setValue(STORAGE_KEY_CUSTOM_PENALTY_KICK_TIME, null);
    Storage.setValue(STORAGE_KEY_CUSTOM_USE_CONVERSION_TIMER, null);
    Storage.setValue(STORAGE_KEY_CUSTOM_USE_PENALTY_TIMER, null);
    Storage.setValue(STORAGE_KEY_CUSTOM_PROFILE_IS_7S, null);
    Storage.setValue(STORAGE_KEY_MATCH_PROFILE_ID, null);
}

function clearSavedGameStorage() {
    Storage.setValue(STORAGE_KEY_GAME_STATE_DATA, null);
    Storage.setValue(STORAGE_KEY_LAST_GAME_SUMMARY, null);
    Storage.setValue(STORAGE_KEY_EVENT_LOG_EXPORT, null);
}
