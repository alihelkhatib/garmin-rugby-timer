#!/usr/bin/env bash
set -euo pipefail

# Build and hint-run tests. Adjust CONNECTIQ_SDK and DEVELOPER_KEY environment variables as needed.
SDK="${CONNECTIQ_SDK:-/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b}"
KEY="${DEVELOPER_KEY:-/Users/600171959/developer_key}"
OUT="bin/tests.prg"
DEVICE="${TEST_DEVICE:-fenix6}"
SIM_DEVICE_ID="${SIM_DEVICE_ID:-1}"

echo "Building test PRG..."
"$SDK/bin/monkeyc" -f test_monkey.jungle -o "$OUT" -d "$DEVICE" -y "$KEY" -w --unit-test
echo "Built $OUT"

echo "Run with: \"$SDK/bin/monkeydo\" \"$OUT\" \"$SIM_DEVICE_ID\" -t"
