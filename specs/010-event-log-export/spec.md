# Feature Spec: Event Log Export

## Context
Specify the exported format for match/event logs and the required fields for interoperability and analysis.

## Export format
- Primary export is JSON. Export payload is a single JSON object with keys:
  - `metadata`: { `device`: String, `appVersion`: String, `recordedAt`: ISO8601 }
  - `match`: { `homeTeam`: String (optional), `awayTeam`: String (optional), `finalScore`: { home: Int, away: Int } }
  - `events`: Array of event objects, each event:
    - `time`: String (MM:SS)
    - `type`: String (e.g., `try`, `conversion`, `card`, `penalty`, `drop_goal`)
    - `description`: String
    - `isHome`: Boolean (optional)
    - `scoreAfter`: { home: Int, away: Int } (optional)
    - `gpsSegment`: optional array of `{ lat, lon, timestamp }` if GPS was enabled during match

## Key behaviors
- Export must include GPS segments only if `gpsRecordingEnabled` was true for that match.
- Export should not include device-specific runtime-only state (internal timers, debug profiler flags).
- Export process must be robust to partial/nonexistent GPS data and still produce a valid JSON document.

## Acceptance scenarios
1) Export with GPS
- Given a completed match with GPS enabled
- When user exports
- Then JSON includes `gpsSegment` arrays for events/segments as appropriate

2) Export without GPS
- Given GPS disabled
- When user exports
- Then `gpsSegment` fields are absent and export is valid JSON

## Mocks & instrumentation
- Mock persisted snapshots and recording segments to assert exported JSON structure and optional inclusion of GPS

## Files referenced
- source/RugbyTimerPersistence.mc
- source/RugbyTimerEventLog.mc
- specs/007-gps-privacy-export/spec.md
