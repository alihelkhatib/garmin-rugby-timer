# CI spec (recommended)

## Purpose
Provide a platform-agnostic recommendation for CI jobs that can build the app, produce test artifacts, and surface build/test results for PRs. This repository does not include an active CI workflow; the guidance below may be adapted to your chosen CI provider.

## Goals
- Compile the app and test targets
- Produce the test PRG artifact for review
- Run the unit-test compilation step (simulator-driven E2E tests require a runner with the Connect IQ Simulator)

## Runner requirements
- Java 11+
- Connect IQ SDK installed and accessible on the runner
- Secure handling of the developer key for signed builds (store secrets securely)

## Example steps (platform-agnostic)
1. Checkout the repository
2. Install Java 11 on the runner
3. Install or restore the Connect IQ SDK and make it available via `CONNECTIQ_SDK`
4. Build the test PRG:

```bash
"$CONNECTIQ_SDK/bin/monkeyc" -f test_monkey.jungle -o bin/garminrugbytimer-test.prg -d fenix6 -y developer_key -w --unit-test
```

5. Persist `bin/garminrugbytimer-test.prg` as an artifact in the CI system or upload to your artifact storage.

## Notes
- Many hosted runners cannot run the full GUI simulator; prefer headless compilation and artifact creation in CI. If you require simulator-driven E2E runs, run them on developer machines or a self-hosted runner with the Connect IQ Simulator installed.
- If a CI workflow is added, document its behavior and secrets usage in `log.md` and the project docs.
