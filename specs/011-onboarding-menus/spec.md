# Feature Spec: Onboarding & Menus

## Context
Define the lightweight first-run onboarding, menu expectations, and how onboarding surfaces GPS defaults and initial game-type choices.

## Preconditions
- First-run flag in Storage absent; tests should clear onboarding flag to simulate first run.

## Key behaviors
- On first run the app shows a brief onboarding card explaining:
  - Default game type (7s) and where to change it
  - GPS recording is enabled by default and can be disabled in Settings
  - How to start a match and access Settings/Lock
- The onboarding is dismissible and recorded; it runs once unless the user requests it again from Settings.
- Menus (undo, event log, lock, settings) must follow existing delegate contract and be testable from the main screen; `Half Timer` must be disabled while match in progress.

## Acceptance scenarios
1) First-run onboarding
- Given no `hasSeenOnboarding` key
- When user opens app
- Then a dismissible onboarding card appears and `hasSeenOnboarding` is written to Storage after dismissal

2) Re-show onboarding
- Given onboarding dismissed
- When user selects `Show Onboarding` from Settings
- Then onboarding appears again

3) Menus behavior
- Given main timer screen
- When user opens the main menu
- Then Undo, Event Log, Lock, Settings are present and correspond to documented behavior; `Half Timer` is disabled while playing

## Mocks & instrumentation
- Mock Storage for the onboarding flag and verify writes. Mock UI navigation to assert menu items enabled/disabled state.

## Files referenced
- source/RugbyTimerMenus.mc
- source/RugbyTimerDelegate.mc
- specs/009-settings-match-profiles/spec.md
