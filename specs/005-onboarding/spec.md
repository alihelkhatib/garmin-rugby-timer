# Onboarding spec (developer setup)

## Purpose
Make it quick for a new contributor to get the project building locally.

## Preflight
- Clone the repository
- Install Java (JDK 11+)
- Install Connect IQ SDK (compatible version shipped with project notes)

## Developer key
- Place your `developer_key` at the repository root. This project historically expects the developer key at the root (see AGENTS.md). Treat the key as secret — do not publish it.

## Quick start
```bash
git clone <repo>
cd garmin-rugby-timer
export CONNECTIQ_SDK="/path/to/ConnectIQ_SDK"
java -Xms1g -jar "$CONNECTIQ_SDK/bin/monkeybrains.jar" -o bin/garminrugbytimer.prg -f monkey.jungle -y developer_key -d fenix6_sim -w
```

## Notes
- If you do not have a physical device, use the simulator device `fenix6_sim` for iterative development.
