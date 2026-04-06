# Build spec

## Purpose
Document the exact local build steps for producing the app PRG and the unit-test PRG so contributors can reproduce builds.

## Prerequisites
- Java 11+ (JDK 11 or later) on PATH
- Connect IQ SDK installed and path available in `CONNECTIQ_SDK` or known local path
- `developer_key` file placed at the repository root (project expects a developer key at repo root)
- `monkey.jungle` project descriptor present at repository root

## Environment example (macOS)
Set SDK path (one-time):

```bash
export CONNECTIQ_SDK="/path/to/ConnectIQ_SDK"
```

## Build commands
Build the signed release PRG (signed with `developer_key`):

```bash
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar "$CONNECTIQ_SDK/bin/monkeybrains.jar" \
  -o bin/garminrugbytimer.prg -f monkey.jungle -y developer_key -d fenix6_sim -w
```

Build the test PRG (produces `bin/garminrugbytimer-test.prg`):

```bash
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar "$CONNECTIQ_SDK/bin/monkeybrains.jar" \
  --unit-test -o bin/garminrugbytimer-test.prg -f monkey.jungle -y developer_key -d fenix6_sim -w
```

## Artifacts
- `bin/garminrugbytimer.prg` — signed release PRG
- `bin/garminrugbytimer-test.prg` — unit-test PRG

## Logging
- Record every build command and simulator/device used in `log.md` as project policy.
