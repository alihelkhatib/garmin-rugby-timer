# Repository Guidelines

## Project Structure & Module Organization
- `source/` houses the Monkey C classes. `RugbyTimerView.mc` is the rendering/logic surface, `RugbyTimerDelegate.mc` wires the buttons, and `RugbyTimerApp.mc` wires the behaviors and resources.
- `resources/` contains menus, strings, layouts, and drawables; keep the launcher bitmap in `resources/drawables/` and list it from `resources/drawables/drawables.xml`.
- `resources/menus/menu.xml` defines the main menu stack; the Exit / Back menu also exposes the Event Log entry now so referees can open the log via that dialog while in-play.
- Build outputs land in `bin/`, while `monkey.jungle` is the project descriptor read by `monkeyc`. Manifest metadata and permissions live in `manifest.xml`.
- Use `project_technical_document.md` for architecture notes and `log.md` to record the narrative of each session so future agents can resume work quickly.

## Build, Test, and Development Commands
- Build with the Connect IQ compiler: `monkeyc -f monkey.jungle -o bin\rugbytimer.prg -y developer_key -d fenix6`. Adjust the `-d` flag per target (fenix6pro, fenix6s, fenix6spro, fenix6xpro); the SDK lives under the provided `connectiq-sdk-win-8.3.0-...`.
- After compilation, load the resulting `.prg` into the Fenix 6 simulator (via the SDK’s `monkeydo` or Garmin Express) to verify layout, conversion workflow, and card timers.
- Document any manual validation steps in `log.md`, e.g., “Built with `monkeyc ...` and confirmed countdown timer spacing on the Fenix 6 simulator.”

## Coding Style & Naming Conventions
- Follow Monkey C idioms: 4-space indentation, PascalCase for classes/menus, camelCase for functions/fields, and ALL_CAPS constants. Prefer descriptive names (`countdownRemaining`, `yellowHomeTimes`, `triggerYellowTimerVibe`).
- Keep inline comments tight and explain non-obvious math (layout offsets, timer stacking, and persistent keys). Add doc comments in `project_technical_document.md` when new flows appear.
- Stick to ASCII characters unless existing assets already contain Unicode; file encodings should stay consistent with the SDK expectations.

## Testing Guidelines
- There are no automated tests yet. Use the simulator to confirm timer positions, countdown/clock separation, card and conversion handling, and the 30-second warning haptic.
- Track manual regressions in `log.md` with the date, short summary, and steps taken (include the command used to build the project).
- When introducing new logic (e.g., additional card timers, GPS recording), note the coverage expectations so future agents know what to verify.

## Commit & Pull Request Guidelines
- Keep each commit focused and describe it in present tense (examples: “Clarify timer layout comments,” “Add 40×40 launcher icon,” “Update contributor docs”). Avoid bundling unrelated fixes.
- Every substantive code or resource change must be followed by its own git commit so the history remains easy to trace.
- A PR should include a short summary, the key files touched, and the manual tests executed (mention the `monkeyc` command used and any simulator checks). Add screenshots only if they illustrate a UI change.
- Link to the relevant `log.md` entry if the change follows from a previous session, and mention any outstanding items for the next contributor at the end of the PR description.

## Documentation & Collaboration Expectations
- Every code change must include inline context comments or reference documentation (`project_technical_document.md`, `log.md`) so any future agent can trace why logic evolved, especially for the special timer overlay and conversion/penalty handling.
- Log each session's work in `log.md`, describing the change, why it was made, and how it was validated (mention the `monkeyc` command). Update the log whenever overlay behavior, save-game flow, or button mappings change.
- Keep `AGENTS.md` current when you add new UX rules (e.g., countdown label color, hint swaps, conversion confirmation) so every contributor reads the rules before touching the code.
