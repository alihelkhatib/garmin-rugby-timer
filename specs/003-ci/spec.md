# CI spec (GitHub Actions)

## Purpose
Define CI jobs to build the app, produce test artifacts, and surface build/test results for PRs.

## Goals
- Compile the project on push and pull-request
- Produce and upload the test PRG as a CI artifact
- Run unit-test compilation (and runtime test steps where headless execution is supported)
- Publish signed PRG and optionally upload to Connect IQ Store on release events

## Required secrets
- `CONNECTIQ_SDK_URL` or preinstalled SDK on the runner
- `DEVELOPER_KEY` (path or file contents; keep secure)
- `CONNECTIQ_STORE_TOKEN` (optional — used only for store uploads)

## Example workflow (outline)

```yaml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          java-version: '11'
      - name: Download Connect IQ SDK
        run: |
          # download or restore SDK to $HOME/connectiq
          echo "Install or restore Connect IQ SDK here"
      - name: Build test PRG
        run: |
          java -Xms1g -Dfile.encoding=UTF-8 -jar "$HOME/connectiq/bin/monkeybrains.jar" \
            --unit-test -o bin/garminrugbytimer-test.prg -f monkey.jungle -y developer_key -d fenix6_sim -w
      - name: Upload test artifact
        uses: actions/upload-artifact@v4
        with:
          name: garmin-test-prg
          path: bin/garminrugbytimer-test.prg

  release:
    if: startsWith(github.ref, 'refs/tags/')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build signed PRG
        run: |
          java -Xms1g -Dfile.encoding=UTF-8 -jar "$HOME/connectiq/bin/monkeybrains.jar" \
            -o bin/garminrugbytimer.prg -f monkey.jungle -y developer_key -d fenix6
      - name: Upload to Connect IQ Store (optional)
        if: ${{ secrets.CONNECTIQ_STORE_TOKEN }}
        run: |
          echo "Upload step using CONNECTIQ_STORE_TOKEN"
```

Notes:
- CI runners typically cannot run the full GUI simulator; prefer headless compilation and unit-test generation. If you require simulator-driven E2E runs, use developer machines or a self-hosted runner with the Connect IQ Simulator installed.
