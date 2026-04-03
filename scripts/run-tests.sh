#!/usr/bin/env bash
set -euo pipefail

# Build the Garmin unit-test PRG and optionally run it in the simulator.
#
# Purpose: keep the unit-test target build and the simulator test invocation in
# one repeatable script that uses the SDK's correct `monkeydo <prg> <id> -t`
# syntax for this project.
SDK="${CONNECTIQ_SDK:-/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b}"
KEY="${DEVELOPER_KEY:-/Users/600171959/developer_key}"
OUT="bin/tests.prg"
DEVICE="${TEST_DEVICE:-fenix6}"
SIM_DEVICE_ID="${SIM_DEVICE_ID:-1}"
RUN_SIM_TESTS="${RUN_SIM_TESTS:-0}"

echo "Building test PRG..."
"$SDK/bin/monkeyc" -f test_monkey.jungle -o "$OUT" -d "$DEVICE" -y "$KEY" -w --unit-test
echo "Built $OUT"

if [[ "$RUN_SIM_TESTS" == "1" ]]; then
  echo "Running simulator unit tests on device id $SIM_DEVICE_ID..."
  "$SDK/bin/monkeydo" "$OUT" "$SIM_DEVICE_ID" -t
else
  echo "Run with: RUN_SIM_TESTS=1 SIM_DEVICE_ID=$SIM_DEVICE_ID \"$0\""
  echo "Or manually: \"$SDK/bin/monkeydo\" \"$OUT\" \"$SIM_DEVICE_ID\" -t"
fi
