# Design: resolving ambiguities for specs 003–011

This design proposes concrete, testable decisions for the ambiguous areas surfaced in the spec audit and describes how to implement them safely.

1) Scoring
- Recommendation: adopt standard rugby scoring constants in `RugbyScoringService`:
  - try = 5
  - conversion = 2
  - penalty_goal = 3
  - drop_goal = 3
  - penalty_try = 7 (applied atomically when event recorded)
- Implementation: add constants and unit tests asserting `applyScore(event)` yields expected scores and persisted `lastEvents` payloads.

2) Card durations
- Recommendation (defaults):
  - 7s: Yellow = 120s (2:00), Red = PERM
  - 15s: Yellow = 600s (10:00), Red = PERM
- Expose these as configuration constants and Settings values if future tuning is desired.
- Implementation: `RugbyDisciplineService` holds per-format duration table; `RugbyTimerTiming` consumes durations to start suspension timers.

3) Conversion countdown
- Recommendation: default = 90 seconds for 15s matches and 30 seconds for 7s matches. Expose these as per-game-type settings (e.g., `conversionTimeoutSeconds15s` and `conversionTimeoutSeconds7s`) or a single `conversionTimeoutSeconds` read through the current game-type context so they are configurable via Settings.
- Implementation: overlay reads the current game type and uses the corresponding conversion timeout; tests assert overlay pauses the main countdown for the configured timeout and resumes correctly.

4) Export & timestamps
- Recommendation: use ISO8601 (UTC) for `recordedAt` and each GPS point `timestamp` to avoid timezone ambiguity.
- Implementation: `RugbyTimerPersistence` serializes timestamps via `Util.formatISO8601()` before export; tests validate JSON schema.

5) Persistence recovery & atomic writes
- Recommendation:
  - Use atomic write pattern: write to temporary Storage key `snapshot_tmp`, then `Storage.setValue("snapshot", snapshot_tmp)` or write a versioned wrapper.
  - On `Storage.setValue` failure: retry once after 250ms; if still failing, keep in-memory state and continue silently (per your preference). Record the failure to internal debug log only.
- Implementation: update `RugbyTimerPersistence.saveState()` with atomic write/rename pattern and retry/backoff logic; add unit tests simulating Storage throws and corrupted payloads.

6) Overlay stacking & queueing
- Recommendation: overlays are FIFO, but conversion/penalty overlays are high-priority and will preempt non-critical overlays (menus/help). When preempted, the preempted overlay is pushed to the front of the queue and will re-open after the higher-priority overlay closes.
- Implementation: `RugbyTimerView` maintains an overlay queue with priority ordering; add tests for queue transitions and re-open behavior.

7) Haptics patterns
- Recommendation: define two reference patterns (mapped per device):
  - `shortConfirm`: single 50ms pulse
  - `longExpiry`: single 300ms pulse
  - Rate-limit: no more than 1 haptic per second
- Implementation: centralize haptics calls in `RugbyTimerView` helpers and mock Device.vibrate in tests.

8) GPS default-on + exports
- Already chosen: default-on (opt-out) via `gpsRecordingEnabled` boolean in Settings.
- Implementation: `RugbyRecordingService` checks `gpsRecordingEnabled` before starting Activity; exports include `gpsSegment` only when enabled.

9) Small UX rules
- Menus cannot be opened while a blocking high-priority overlay is visible. Non-blocking overlays (help banners) may coexist.

Notes
- These defaults were chosen to align with standard rugby practice and to make tests deterministic. If you prefer alternative numbers, confirm and the specs will be updated.
