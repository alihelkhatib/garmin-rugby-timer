# Repository Guidelines

## Project Structure & Module Organization
- `source/` holds all Monkey C source files (`App`, `Delegate`, `View`, `Settings`); `resources/` stores Connect IQ assets (menus, strings, layouts).
- `bin/` contains build outputs; `manifest.xml` configures the app metadata.
- `log.md` and `project_technical_document.md` record session history and architecture notes. Keep `debug.png` and other art assets in repo root if used for references.

## Build, Test, and Development Commands
- `monkeyc -f monkey.jungle -o bin\rugbytimer.prg -y developer_key -d fenix6`: compiles the project using the active SDK, producing the `.prg` binary and debug XML.
- Open the generated `.prg` in the Fenix 6 simulator via Garmin Express or the SDK’s `monkeydo` for visual verification; there is no automated test suite yet.
- Use the provided `monkeybrains.jar` path (see `developer_key` and SDK version) in all build commands to ensure proper signing.

## Coding Style & Naming Conventions
- Stick to Monkey C idioms: 4-space indentation, PascalCase for classes, camelCase for functions/variables, and constants in ALL_CAPS_WITH_UNDERSCORES.
- Favor descriptive variable names (e.g., `countdownRemaining`, `yellowHomeTimes`), keep inline comments short, and document non-obvious logic in `project_technical_document.md`.
- Monkey C enforces ASCII for source files; avoid introducing Unicode unless the source already includes it.

## Testing Guidelines
- No automated tests currently exist; rely on simulator/driven manual flows described in `project_technical_document.md`.
- When adding tests later, place them under a dedicated `tests/` directory and run with `monkeyc` plus any simulation harness the SDK provides.
- Document manual verification steps (e.g., verifying timers/card layout on Fenix 6) in `log.md`.

## Commit & Pull Request Guidelines
- Commit titles should describe the change concisely (e.g., “Refine timer layout spacing”, “Log layout session”). Avoid merging unrelated work in a single commit.
- Each PR should include a summary of added features/bug fixes, mention impacted files, and note any manual verification performed (e.g., “Built with `monkeyc ...` and checked layout on Fenix 6 simulator”).
- When touching user-visible behavior, link to any relevant issue/bug and include before/after screenshots if available.

## Agent-specific Instructions
- Update `log.md` at the end of every session with the date, concise summary, and notable decisions so future agents can resume quickly.
- Keep `project_technical_document.md` synchronized with architectural decisions; add sections or update descriptions when introducing new flows or state storage keys.
- If rebuilding after changes, capture the success/failure output to reference later and mention it in the session log.
