# Team Identity Customization Spec

## Status

Phase 1 implemented on 2026-04-06.

Current implementation:

- Preset-based `Team Labels` setting
- Idle-only editing flow
- Persistent custom-profile storage
- Main score-area labels
- Event-log and finalized summary labeling

Still deferred:

- Team color accents
- Any free-form naming flow

## Goal

Allow referees and coaches to distinguish the two sides more clearly during a match
without introducing laborious text entry on devices like the Garmin Fenix 6.

## Primary Design Constraint

The target device class includes watches with five physical buttons and no keyboard-first
interaction model. Free-form team-name entry is intentionally de-prioritized because it
would be slow, error-prone, and frustrating during pre-match setup.

## Recommendation Summary

Implement team identity customization in phases:

1. Add low-friction team label presets.
2. Add optional team color accent presets.
3. Defer any free-form team naming unless a later release proves it is truly needed.

This keeps the feature practical on Fenix-class devices while still delivering meaningful
value to users.

## Proposed Feature Scope

### Phase 1: Team Label Mode

Add a settings item named `Team Labels` with the following modes:

- `Home / Away`
- `Team A / Team B`
- `Light / Dark`
- `Red / Blue`
- `Custom Preset`

`Custom Preset` should not mean arbitrary text entry. It should open a short list of
common label pairs such as:

- `Sharks / Blues`
- `1st XV / 2nd XV`
- `Varsity / JV`
- `A / B`

The exact preset list can stay small in the first version.

Implementation note:

The shipped Phase 1 keeps the same idea but flattens the selection into one preset list
for faster button-driven navigation on Fenix-class hardware.

### Phase 2: Team Color Accent Mode

Add a settings item named `Team Colors` with simple preset pairs that affect score/card
accent rendering where safe. Suggested options:

- `Default`
- `Red / Blue`
- `Green / White`
- `Yellow / Black`
- `Light / Dark`

Use these colors conservatively. The watch display must remain readable on Fenix-class
screens, and red/yellow disciplinary colors must stay distinct from team accents.

### Explicit Non-Goals For Initial Release

- No on-watch free-form text entry
- No long team-name editor
- No per-character picker UI
- No logo upload or custom bitmap support
- No attempt to recolor every part of the UI

## User Experience Proposal

### Settings Flow

Add two new items to the settings menu:

- `Team Labels`
- `Team Colors`

Behavior:

- Both should be editable only while the app is idle.
- Both should persist through storage like other settings.
- Manual edits should promote the active profile to `Custom`, following the same pattern
  already used by timer/profile settings.

### In-Match Display

Apply team labels in these places first:

- Score area labels if present
- Event log entries
- Match summary
- Saved/exported event log text

Apply team color accents only in low-risk locations:

- Score labels or small side markers
- Optional subtle indicators near the score columns

Do not recolor:

- Main countdown digits
- Red/yellow card semantics
- Overlay warning colors
- Core pause/alert status colors

## Storage Proposal

Add new storage-backed settings:

- `teamLabelMode`
- `teamColorMode`
- `customTeamLabelPresetId`

If a profile-based approach is used, these should become part of the stored custom profile
payload and any future profile schema that represents editable match presentation options.

## Rendering Rules

### Labels

The renderer should resolve the active label pair once per draw/update path via a helper.

Example resolved pairs:

- `Home`, `Away`
- `Team A`, `Team B`
- `Light`, `Dark`
- `Red`, `Blue`

### Colors

Use a helper to resolve team accent colors, but keep a strict fallback to the current
white/default rendering if:

- the selected pair is unavailable
- the display would become low-contrast
- the state being rendered already has semantic color meaning

## Suggested Implementation Shape

### New Helper / Support Logic

Potential additions:

- `RugbyTeamIdentitySupport`
  Purpose: resolve label pair, color pair, defaults, and storage/profile fallback rules.

- Extend `MatchProfileEntry`
  Add optional team identity fields only if the project wants team identity to be profile-driven.

### Files Likely To Change

- `source/RugbySettingsMenu.mc`
- `source/RugbySettingsNavigation.mc`
- `source/RugbySettingsSupport.mc`
- `source/RugbyGameModel.mc`
- `source/RugbyMatchProfiles.mc`
- `source/types/MatchProfileEntry.mc`
- `source/RugbyTimerRenderer.mc`
- `source/RugbyTimerEventLog.mc`
- `source/types/MatchSummaryEntry.mc`
- `resources/strings/strings.xml`

Possible new files:

- `source/support/RugbyTeamIdentitySupport.mc`

## Test Plan

### Unit Tests

Add tests for:

- label mode resolution
- color mode resolution
- storage/profile fallback behavior
- idle-only settings enforcement
- custom-profile promotion when labels/colors change

### Integration Tests

Add tests for:

- selected label mode persists across restart
- event log uses resolved labels
- match summary uses resolved labels
- changing team identity while idle does not break existing timing/profile behavior

### Manual Verification

Verify on watch/simulator:

- settings navigation remains quick on a Fenix 6
- labels are readable on the main screen
- color accents do not conflict with red/yellow card meaning
- event log and post-match summary remain easy to scan

## Acceptance Criteria

- A user can choose a team label mode without any free-form text entry.
- The chosen label pair persists across app restarts.
- The labels appear in the main score presentation, event log, and summary/export paths.
- Optional team colors remain readable and do not override disciplinary or warning semantics.
- The setup flow stays practical on a five-button watch.

## Future Extension Path

If users strongly request richer naming later, add a second-generation preset builder rather
than true free-form text first. Example:

- choose from a short list of nouns
- choose from a short list of abbreviations
- choose from a short list of school/team archetypes

That still fits button-driven interaction much better than character-by-character entry.
