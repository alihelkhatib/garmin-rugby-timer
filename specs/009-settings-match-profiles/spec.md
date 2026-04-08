# Feature Spec: Settings & Match Profiles

## Context
Document settings behavior, profile persistence, and canonical storage keys. This reconciles the earlier naming ambiguity by specifying canonical keys and migration behavior.

## Preconditions
- Tests should mock Storage and verify key reads/writes.

## Canonical keys & migration
- `halfDuration7s` — integer minutes for 7s games
- `halfDuration15s` — integer minutes for 15s games
- `lastGameType` — string, one of `"7s"` or `"15s"`
- Migration rule: if older keys like `rugby7s` are present, their values should be honored on load and rewritten to the canonical keys.

## Key behaviors
- Settings exposes a `Half Timer` picker that edits the canonical per-game-type key. It is disabled while a match is in progress.
- Editing the Half Timer while idle updates the UI immediately and persists the choice (debounced per persistence rules) for the corresponding game type.
- Selecting a game type on new-game setup loads the corresponding canonical duration.

## Acceptance scenarios
1) Edit half-duration from Settings
- Given app idle and lastGameType == `7s`
- When user sets half duration to 18
- Then `halfDuration7s` updates to 18 and countdown reflects 18:00 when returning to main screen

2) Disabled while playing
- Given match in progress
- When user opens Settings
- Then `Half Timer` entry is disabled and not editable

3) Migration
- Given legacy key `rugby7s` present on Storage
- When app loads
- Then `halfDuration7s` is populated from `rugby7s` and migration writes canonical keys back to Storage

## Mocks & instrumentation
- Mock Storage to simulate presence/absence of legacy keys and to assert canonical writes.

## Files referenced
- source/RugbySettingsPickers.mc
- source/RugbyMatchProfiles.mc
- specs/002-custom-half-timer/spec.md
