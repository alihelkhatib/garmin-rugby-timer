# Feature Spec: GPS Privacy & Export

## Context
Define GPS recording consent policy and export behavior. Policy chosen: Default-on (opt-out). The app records Activity.SPORT_RUGBY by default; user can disable recording in Settings.

## Preconditions
- Tests should mock `Activity`/recording APIs and Storage for the GPS Settings flag.

## Key behaviors
- GPS recording is enabled by default on first run.
- A persistent Settings toggle `gpsRecordingEnabled` allows users to disable future recordings.
- If a device/runtime does not support SPORT_RUGBY recording, app continues without crashing and surfaces a short non-blocking status message.
- Event-log and match exports include GPS segments only when `gpsRecordingEnabled` was true during that match.

## Acceptance scenarios
1) Default-on recording
- Given first app launch
- Then GPS recording is enabled by default (start recording on match start) and `gpsRecordingEnabled` stored true unless user disables

2) Disable recording via Settings
- Given recording is enabled
- When user disables in Settings
- Then subsequent match recording does not start and exports exclude GPS segments

3) Export respects consent
- Given a completed match with GPS enabled
- When user exports the match
- Then exported payload includes `gpsSegment` array; if GPS disabled then `gpsSegment` is absent

4) Device lacking support
- Given device does not support SPORT_RUGBY
- Then app continues running the timer, does not crash, and shows a short status message about recording unavailability

## Mocks & instrumentation
- Mock recording APIs to simulate successful recording, user-disabled recording, and unsupported-device behavior.

## Files referenced
- source/RugbyRecordingService.mc
- source/RugbyTimerPersistence.mc
- manifest.xml (permissions)
