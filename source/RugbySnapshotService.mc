using Toybox.Application.Storage;
using Toybox.System;

/**
 * Snapshot/persistence orchestration service for the public game model.
 *
 * Purpose: own save/reset/finalize/export side effects so lifecycle writes and
 * summary generation stay consistent across app stop, reset, and finish flows.
 */
class RugbySnapshotService {
    static function persistState(model) {
        try {
            RugbyTimerPersistence.saveState(model);
            model.lastPersistTime = System.getTimer();
        } catch (ex) {
            System.println("Error persisting state: " + ex.getErrorMessage());
            model.setStatusMessage("Save failed");
        }
    }

    static function handleAppStop(model) {
        if (model.gameState != STATE_IDLE && model.gameState != STATE_ENDED) {
            RugbySnapshotService.persistState(model);
        }
        RugbyRecordingService.stopRecording(model);
    }

    static function resetGame(model) {
        RugbyRecordingService.stopRecording(model);
        model.resetMatchRuntimeState();
        RugbySnapshotService.persistState(model);
        Storage.setValue(STORAGE_KEY_GAME_STATE_DATA, null);
    }

    static function saveGame(model) {
        try {
            RugbyTimerPersistence.finalizeGameData(model);
            RugbySnapshotService.persistState(model);
        } catch (ex) {
            System.println("Error saving finished match: " + ex.getErrorMessage());
            model.setStatusMessage("Save failed");
        }
    }

    static function finalizeGame(model) {
        try {
            RugbyTimerPersistence.finalizeGameData(model);
            Storage.setValue(STORAGE_KEY_GAME_STATE_DATA, null);
        } catch (ex) {
            System.println("Error finalizing game: " + ex.getErrorMessage());
            model.setStatusMessage("Save failed");
        }
    }

    static function exportEventLog(model) {
        RugbyTimerEventLog.exportEventLog(model);
    }

    static function showEventLog(model) {
        RugbyTimerEventLog.showEventLog(model);
    }
}
