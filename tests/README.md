# Running unit tests (Connect IQ SDK)

Quick steps to build and run the unit tests in the simulator.

1. Build the app PRG and test PRG together with the local helper:

```bash
./scripts/validate-local.sh
```

2. Or build only the test PRG including unit tests. From the project root run the SDK `monkeyc` compiler (replace `<SDK_BIN>` with your SDK bin path):

```bash
"<SDK_BIN>/monkeyc" -f test_monkey.jungle -o bin/tests.prg -d fenix6 -y <DEVELOPER_KEY> -w --unit-test
```

3. Launch the simulator and run the tests with `monkeydo` (or use the Monkey C extension Test Explorer in VS Code). This SDK build expects a simulator device id before `-t`:

```bash
"<SDK_BIN>/monkeydo" bin/tests.prg 1 -t
```

Notes:
- Unit tests must be annotated with `(:test)` and take a `logger as Logger` parameter; they should return `true` for pass and `false` for fail.
- Tests are only compiled/executed when the `--unit-test` flag is present; test code is removed from release builds.
- The Connect IQ Language Server (used by the VS Code extension) provides style/warning checks. The SDK compiler (`monkeyc`) also emits warnings; there is no separate dedicated "monkey-style" linter binary, so rely on the Language Server and compiler warnings for style enforcement.

Recommended workflow:
- Use the VS Code Monkey C Test Explorer to run and iterate tests quickly.
- Run `monkeyc` with `--unit-test` on CI to produce a test PRG and execute it with `monkeydo` in the simulator.
- Or use `scripts/run-tests.sh`, which builds the test PRG with `--unit-test` and prints the matching simulator command.
- Or use `scripts/validate-local.sh` to build both the app PRG and the unit-test PRG before printing the same simulator command.
