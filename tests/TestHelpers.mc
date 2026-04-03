using Toybox.Application.Storage;

// Shared test helpers used by multiple test files.
function clearCustomStorage() {
    Storage.setValue("customHalfDuration", null);
    Storage.setValue("customConversionTime", null);
    Storage.setValue("customKickoffTime", null);
    Storage.setValue("customPenaltyKickTime", null);
    Storage.setValue("customUseConversionTimer", null);
    Storage.setValue("customUsePenaltyTimer", null);
    Storage.setValue("customProfileIs7s", null);
    Storage.setValue("matchProfileId", null);
}
