#!/usr/bin/env bash
# Runs build_runner and reports any issues.
set -euo pipefail
echo "Running build_runner..."
dart run build_runner build --delete-conflicting-outputs
echo "Done."
