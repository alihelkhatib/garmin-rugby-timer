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
            System.println("Error persisting state");
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
        RugbyTimerPersistence.finalizeGameData(model);
        RugbySnapshotService.persistState(model);
    }

    static function finalizeGame(model) {
        RugbyTimerPersistence.finalizeGameData(model);
        Storage.setValue(STORAGE_KEY_GAME_STATE_DATA, null);
    }

    static function exportEventLog(model) {
        RugbyTimerEventLog.exportEventLog(model);
    }

    static function showEventLog(model) {
        RugbyTimerEventLog.showEventLog(model);
    }
}
