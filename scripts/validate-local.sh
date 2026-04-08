#!/usr/bin/env bash
set -euo pipefail

SDK="${CONNECTIQ_SDK:-/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b}"
KEY="${DEVELOPER_KEY:-/Users/600171959/developer_key}"
DEVICE="${TEST_DEVICE:-fenix6}"
APP_OUT="${APP_OUT:-bin/rugbytimer.prg}"
TEST_OUT="${TEST_OUT:-bin/tests.prg}"
SIM_DEVICE_ID="${SIM_DEVICE_ID:-1}"

echo "Building app PRG..."
"$SDK/bin/monkeyc" -f monkey.jungle -o "$APP_OUT" -d "$DEVICE" -y "$KEY" -w
echo "Building unit-test PRG..."
"$SDK/bin/monkeyc" -f test_monkey.jungle -o "$TEST_OUT" -d "$DEVICE" -y "$KEY" -w --unit-test

echo "Validation builds passed."
echo "To run unit tests in the simulator:"
echo "\"$SDK/bin/monkeydo\" \"$TEST_OUT\" \"$SIM_DEVICE_ID\" -t"
