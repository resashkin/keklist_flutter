#!/bin/bash
set -e

PLATFORM="${1:-all}"   # all | ios | android
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

run_ios() {
  echo "▶ iOS → TestFlight"
  cd "$PROJECT_ROOT/ios"
  bundle exec fastlane build_and_upload_to_testfilght_from_local_machine
  echo "✓ iOS done"
}

run_android() {
  echo "▶ Android → Firebase App Distribution"
  cd "$PROJECT_ROOT/android"
  bundle exec fastlane distribute_firebase
  echo "✓ Android done"
}

case "$PLATFORM" in
  ios)     run_ios ;;
  android) run_android ;;
  all)     run_ios && run_android ;;
  *)
    echo "Usage: $0 [all|ios|android]"
    exit 1
    ;;
esac

echo "✓ Distribution complete"
