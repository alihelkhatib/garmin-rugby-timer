#!/usr/bin/env bash
set -euo pipefail

# Build and hint-run tests. Adjust CONNECTIQ_SDK and DEVELOPER_KEY environment variables as needed.
SDK="${CONNECTIQ_SDK:-/Users/600171959/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b}"
KEY="${DEVELOPER_KEY:-/Users/600171959/developer_key}"
OUT="bin/tests.prg"

echo "Building test PRG..."
"$SDK/bin/monkeyc" -f test_monkey.jungle -o "$OUT" -d fenix6 -y "$KEY" -w
echo "Built $OUT"

echo "Run the PRG on the simulator or device. When launched the test runner prints TESTS PASSED or TESTS FAILED to stdout/logs."
