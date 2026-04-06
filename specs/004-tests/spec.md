# Tests spec

## Purpose
Explain test layout, how to run tests locally, and how to interpret test artifacts produced by the SDK unit-test flow.

## Test layout
- `tests/` — unit and integration test files using SDK `(:test)` annotations
- `tests/TestHelpers.mc` — shared helpers for test setup/teardown
- `tests/TEST_TRACEABILITY.md` — links between requirements and tests

## Run tests locally
1. Build the test PRG (see `specs/002-build/spec.md`):

```bash
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar "$CONNECTIQ_SDK/bin/monkeybrains.jar" --unit-test \
  -o bin/garminrugbytimer-test.prg -f monkey.jungle -y developer_key -d fenix6_sim -w
```

2. Open the Connect IQ Simulator and load `bin/garminrugbytimer-test.prg`.
3. Run the tests using the simulator UI (or headless runner if available). Capture the test output and attach it to the CI run or save in `tests/test-results/`.

## Failures and triage
- Failures should reference the test file and the associated requirement in `tests/TEST_TRACEABILITY.md`.
- If a test fails due to environment (missing SDK, paths), record exact commands and SDK version in `log.md`.
