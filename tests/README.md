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
