#!/usr/bin/env bash
# Runs all unit tests with coverage and opens the lcov report.
set -euo pipefail
flutter test --coverage test/unit/
echo "Coverage written to coverage/lcov.info"
