/**
 * Typed helper for the persisted `{gameState, pausedState}` pair.
 *
 * Purpose: keep the saved live/paused-state shape explicit instead of passing
 * around an untyped two-field dictionary.
 */
class PersistedStatePair {
    var gameState;
    var pausedState;

    static function create(gameState, pausedState) {
        var pair = new PersistedStatePair();
        pair.gameState = gameState;
        pair.pausedState = pausedState;
        return pair;
    }
}
