# Feature Spec: Persistence & Recovery

## Context
Define persistence guarantees, debounced writes, migration, and recovery semantics for invalid or failed Storage payloads.

## Preconditions
- Tests should mock `Storage.getValue` / `Storage.setValue` and validate app behavior under success/failure and corrupted inputs.

## Key behaviors
- Snapshot and event writes are debounced (300 ms) on frequent mutations; lifecycle-critical paths (start/pause/resume/halftime/fulltime/end/reset/app stop) flush pending writes immediately.
- Only plain serializable dictionaries/arrays/strings/numbers/booleans reach Storage.setValue.
- On load, malformed snapshots are detected and cleared; app resets to a safe idle state (no crash).
- On Storage.setValue failures, the app silently falls back to in-memory defaults and continues operating (no user-facing error). Writes should be retried at next flush point where appropriate.
- Migration: legacy symbol-keyed payloads are accepted and transformed into normalized dictionary forms on load.

## Acceptance scenarios
1) Debounced writes
- Given multiple score edits within 300 ms
- When edits complete
- Then a single Storage.setValue occurs with the consolidated snapshot

2) Flush on lifecycle event
- Given pending debounced writes
- When app stop or explicit save is invoked
- Then Storage.setValue is called immediately to persist the latest snapshot

3) Corrupted snapshot on load
- Given Storage contains an invalid snapshot
- When app starts
- Then invalid payload is cleared, app moves to idle safe state, and no crash occurs

4) Storage.setValue error
- Given Storage.setValue throws an exception during a save
- Then app continues (no crash), in-memory state remains consistent, and no user-facing error is shown (silent fallback)

## Mocks & instrumentation
- Simulate Storage throws, corrupted bytes, and legacy payloads to assert recovery and migration paths.

## Files referenced
- source/RugbyTimerPersistence.mc
- source/RugbyGameModel.mc
- docs/CODEBASE_AUDIT.md
