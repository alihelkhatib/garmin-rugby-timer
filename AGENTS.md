# Repository Guidelines

## Workflow Expectations
- Every code or resource change requires its own atomic `git commit` (use present-tense messages such as `Add conversion overlay hints` or `Document timing math`). This keeps `git log` traceable and satisfies the user’s “every change must be committed” requirement.
- Record the work done during each session in `log.md`. Include the `monkeyc` command used for any builds so the next contributor knows how to reproduce the validation.
- Update `project_technical_document.md` with architecture notes when you add new flows (timing helpers, persistence, GPS stats, overlays, etc.) and keep the entry under active maintenance so future agents quickly understand the current topology.

## Project Structure & Module Organization
- `source/` holds the Monkey C code. Key entry points:
  - `RugbyTimerApp.mc` registers the view and delegate.
  - `RugbyTimerDelegate.mc` wires the menus/keys (Back/Lap now surfaces Event Log and Save Game entries).
  - `RugbyTimerView.mc` orchestrates states, overlays, and persistence while delegating layout math.
  - `RugbyTimerRenderer.mc` centralizes font selection, layout offsets (`baseTimerY`, `candidateTimerY`, etc.), and card/gps overlay drawing so spacing is consistent across devices.
  - `RugbyTimerTiming.mc` owns the shared timer loop, countdown/game timer separation, and haptics (including the 30s/15s warnings).
  - `RugbyTimerCards.mc` manages yellow/red timers, numbering (`Y1`, `R1`), stacking rules, and screen persistence.
  - `RugbyTimerOverlay.mc` paints the conversion/kickoff/penalty overlay, keeps the countdown label white, and handles UP/DOWN button hints plus confirmation text.
  - `RugbyTimerPersistence.mc` snapshots/resumes state, clears cards on resets/finishes, and saves the final summary.
  - `RugbyTimerEventLog.mc` formats timestamped entries and exposes the “Save log” action tied to the Exit dialog’s Event Log entry.
- Keep drawables/menus/strings under `resources/`, and update `resources/drawables/drawables.xml` whenever icons or launcher sizes change (launcher icons must match each device’s 40×40 requirement).
- Build artifacts live in `bin/`; `monkey.jungle` is the project descriptor.

## Build, Test, and Development Commands
- Run the compiler via the SDK root:  
  `& 'C:\Users\aliel\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.3.0-2025-09-22-5813687a0\bin\monkeyc' -f monkey.jungle -o bin\rugbytimer.prg -y developer_key -d fenix6`  
  Adjust `-d` per target (fenix6pro, epixpro, venu2, etc.) and note the full path in `log.md` after the build.
- Use the simulator (`simulator.exe` in the same SDK `bin`) or the watch itself to verify conversions, cards, overlays, GPS recording, and event log exports.
- Manual verification steps (state transitions, overlay hints, 30s vibration, event log save) should also be recorded in `log.md`.

## Coding Style & Naming Conventions
- Monkey C style: 4-space indentation, PascalCase classes, camelCase fields/functions, and ALL_CAPS constants. Keep file names descriptive (`RugbyTimerCards`, `RugbyTimerRenderer`).
- Provide inline comments for non-obvious layout math (why `baseTimerY` offsets are used, how `candidateTimerY` predicts where the countdown sits relative to `cardsY`).
- Document new helpers in `project_technical_document.md` and explain any UI changes (e.g., countdown overlay now sits above the conversion timer).
- Avoid Unicode unless asset already contains it; prefer ASCII for compatibility.

## Testing Guidelines
- No automated suite yet; rely on the simulator or real watch for:
  1. Countdown/game timer separation during conversions, penalties, kickoffs, and pauses.
  2. Event Log recording and “Save log” export.
  3. Card timer stacking behavior (max two visible per side, extras hidden but tracked) plus the 10-second yellow warning.
  4. GPS tracking recorded as `Activity.SPORT_RUGBY`.
- If you add new behaviors (overlay screen, event log export, GPS stats), expand `log.md` with the test steps and mention any outstanding verification.

## Commit & Pull Request Guidelines
- Each change must be committed immediately after verification; do not bundle multiple feature deliveries into one commit. Mention the linked `log.md` entry or session notes in the PR description so reviewers understand the intent.
- PRs should summarize affected helpers (renderer, cards, overlay, persistence, timing) and reference the manual tests executed (including the `monkeyc` command).
- Attach screenshots when UI layout changes occur and note Cinemations/haptics if they were touched.

## Documentation & Collaboration Expectations
- Inline code modifications must be accompanied by succinct comments explaining “why,” not just “what.”
- Update `project_technical_document.md` whenever you add a module or change layout rules so future agents can quickly onboard.
- Use `log.md` for chronological session notes, including build/test commands and resulting issues/fixes.
- `AGENTS.md` must stay consistent with the latest instructions—if the user adds new behavior (e.g., overlay hints, event log export, GPS stats), mention it here so every contributor reads the current rules before coding.
