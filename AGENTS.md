# Repository Guidelines

## Project Structure & Module Organization
- source/ houses the Monkey C modules. RugbyTimerApp.mc boots the view/delegate, RugbyTimerDelegate.mc wires the buttons/menus, and RugbyTimerView.mc orchestrates state while delegating drawing to RugbyTimerRenderer.mc and helpers (RugbyTimerTiming, RugbyTimerCards, RugbyTimerOverlay, RugbyTimerPersistence, RugbyTimerEventLog). Keep each module focused: view/state management remains in the view, layout math in the renderer, timing logic in the timing helper, and persistence/log export in their dedicated files.
- esources/ stores drawables (the launcher icon must stay 40×40), layouts, menus, and strings referenced in the manifest. Build artifacts land in in/; the project descriptor is monkey.jungle, and the developer key belongs at the repo root.

## Build, Test, and Development Commands
- Use the bundled SDK (C:\Users\aliel\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.3.0-2025-09-22-5813687a0). monkeyc.exe and monkeybrains.jar live under ...\bin. Build with:
`
java --% -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar <SDK>/bin/monkeybrains.jar -o bin\rugbytimer.prg -f C:\Users\aliel\Projects\rugby-timer\monkey.jungle -y C:\Users\aliel\Projects\rugby-timer\developer_key -d fenix6_sim -w
`
- Log every build command in log.md (include simulator/device details). The GitHub Action mirrors this workflow, produces the PRG, and uploads it to the Connect IQ Store when CONNECTIQ_STORE_TOKEN is populated.

## Coding Style & Naming Conventions
- Stick to four-space indentation, PascalCase for classes, camelCase for methods/fields, and UPPER_CASE for constants. Avoid explicit type hints (ar foo as Number); Monkey C infers local types automatically. Document complex math (why aseTimerY vs. candidateTimerY, card spacing, overlay positioning) with concise inline comments.

## Testing Guidelines
- Manual tests include timing flows (countdown pause/resume, conversion/kickoff/penalty overlays, card timer stacking), event log exports, GPS recording, and the 10-second yellow warning. Run the Java build before any release and confirm the PRG loads into the simulator or hardware.

## Commit & Pull Request Guidelines
- Commit each logical change separately with present-tense messages (e.g., “Resize launcher icon” or “Document timing math”). No change is complete without building, updating log.md, and refreshing project_technical_document.md when you adjust layout, timing, persistence, or release behavior. PR descriptions should cite the tests executed and link to the relevant log.md entry.
