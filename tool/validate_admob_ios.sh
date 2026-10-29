#!/bin/sh
# Xcode Release builds fail here when iOS AdMob IDs are still placeholders
# or ios/Flutter/AdMob.xcconfig is out of date with config/admob.json.
set -eu

if [ "${CONFIGURATION:-}" != "Release" ]; then
  exit 0
fi

ROOT="$(cd "${SRCROOT}/.." && pwd)"

if [ -n "${FLUTTER_ROOT:-}" ] && [ -x "${FLUTTER_ROOT}/bin/dart" ]; then
  DART="${FLUTTER_ROOT}/bin/dart"
elif command -v dart >/dev/null 2>&1; then
  DART="$(command -v dart)"
else
  echo "error: dart not found. Set FLUTTER_ROOT so release AdMob IDs can be checked." >&2
  exit 1
fi

cd "$ROOT"
exec "$DART" run tool/validate_admob.dart --ios
