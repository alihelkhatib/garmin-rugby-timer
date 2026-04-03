#!/usr/bin/env bash
set -euo pipefail

# Build the app, build the unit-test target, and optionally run simulator tests.
#
# Purpose: provide one local validation entrypoint for the release workflow so
# developers do not have to remember separate monkeyc/monkeydo invocations.
SDK="${CONNECTIQ_SDK:-/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b}"
KEY="${DEVELOPER_KEY:-/Users/600171959/developer_key}"
APP_OUT="${APP_OUT:-bin/garminrugbytimer.prg}"
DEVICE="${APP_DEVICE:-fenix6}"

echo "Building app PRG..."
"$SDK/bin/monkeyc" -f monkey.jungle -o "$APP_OUT" -d "$DEVICE" -y "$KEY" -w
echo "Built $APP_OUT"

echo "Building unit-test target..."
"$(dirname "$0")/run-tests.sh"
