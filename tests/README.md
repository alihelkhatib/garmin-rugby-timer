# Running unit tests (Connect IQ SDK)

Quick steps to build and run the unit tests in the simulator.

1. Build the test PRG including unit tests. From the project root run the SDK `monkeyc` compiler (replace `<SDK_BIN>` with your SDK bin path):

```bash
"<SDK_BIN>/monkeyc" -f test_monkey.jungle -o bin/rugbytimer-test.prg -d fenix6 -y <DEVELOPER_KEY> -w --unit-test
```

2. Launch the simulator and run the tests with `monkeydo` (or use the Monkey C extension Test Explorer in VS Code):

```bash
"<SDK_BIN>/monkeydo" bin/rugbytimer-test.prg 1 -t
```

Notes:
- Unit tests must be annotated with `(:test)` and take a `logger as Logger` parameter; they should return `true` for pass and `false` for fail.
- Tests are only compiled/executed when the `--unit-test` flag is present; test code is removed from release builds.
- The Connect IQ Language Server (used by the VS Code extension) provides style/warning checks. The SDK compiler (`monkeyc`) also emits warnings; there is no separate dedicated "monkey-style" linter binary, so rely on the Language Server and compiler warnings for style enforcement.

Recommended workflow:
- Use the VS Code Monkey C Test Explorer to run and iterate tests quickly.
- Run `monkeyc` with `--unit-test` on CI to produce a test PRG and execute it with `monkeydo` in the simulator.
- Use `scripts/run-tests.sh` to build the test PRG, and set `RUN_SIM_TESTS=1 SIM_DEVICE_ID=<id>` when you want it to invoke `monkeydo`.
- Use `scripts/validate-local.sh` when you want one local command that builds the app target and the unit-test target together.

Integration coverage:
- `tests/Test_RugbyIntegrationFlows.mc` holds the multi-step match-flow coverage intended for simulator-backed verification of presets, pause/resume restore, sanction persistence, rugby-only recording startup behavior, conversion made/miss handling, penalty timer expiry, and second-half/end-game flow.
- `tests/Test_RugbyTimerViewSupport.mc` covers the extracted pure presentation rules from `RugbyTimerView`, keeping the view refactor testable without a device context.

Manual regression checklist:
- Idle screen: adjust half length up/down and confirm the countdown updates directly from the main screen without needing a separate settings row.
- Match format flow: open `Settings -> Match Format`, choose `7s`, `10s`, `15s`, and `U19s`, and confirm the active ruleset plus visible settings values update immediately.
- Timer settings flow: change `Conversion Timer`, `Halftime Break`, and `Penalty Kick`, then confirm the settings root shows the new values without bouncing to a stale row.
- Start flow: start a match from idle, confirm the countdown, top elapsed clock, and lock-on-start behavior if enabled.
- Pause/resume flow: pause during live play, wait for the paused reminder cadence, then resume and confirm countdown/card timers continue correctly.
- Conversion flow: record a try, confirm the conversion overlay opens, then test both made and missed paths.
- Penalty flow: trigger a penalty timer path, confirm the overlay/countdown behavior and dismiss path.
- Card flow: issue multiple yellow/red cards for both teams and confirm label order, row limit, and timed/permanent red behavior.
- Team label flow: while idle, switch the `Team Labels` preset and confirm the score labels, new event-log entries, and saved summary/export wording all use the selected pair.
- Halftime/fulltime flow: let the main countdown expire in each half and confirm halftime break countdown, live halftime `+1/-1` adjustment, half-2-ready state, second-half restart, and game end behavior.
- Exit/save flow: open the back/exit menu, test Resume, Save Game, Reset Game, Event Log, and finished-summary behavior.
- Persistence flow: leave and relaunch during a live match and confirm the saved session reopens as a safe paused snapshot.
- GPS/runtime notice flow: start a match on a device or simulator environment that may not support rugby recording and confirm the app either starts recording or surfaces the expected one-shot operational notice.
