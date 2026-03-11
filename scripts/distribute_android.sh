#!/bin/bash

# Firebase App Distribution Helper Script for Android
# Usage:
#   ./scripts/distribute_android.sh                                    # Simple distribution
#   ./scripts/distribute_android.sh "Release notes here"               # With release notes
#   ./scripts/distribute_android.sh "Release notes" "group1,group2"    # With custom groups
#   ./scripts/distribute_android.sh "Release notes" "" "email1,email2" # With custom testers

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANDROID_DIR="$PROJECT_ROOT/android"

# Check if .env file exists
if [ ! -f "$ANDROID_DIR/fastlane/.env" ]; then
    echo -e "${RED}Error: fastlane/.env file not found${NC}"
    echo "Please create android/fastlane/.env with the following content:"
    echo ""
    echo "FIREBASE_APP_ID=your-firebase-app-id"
    echo "FIREBASE_TOKEN=your-firebase-token"
    echo ""
    echo "See FIREBASE_DISTRIBUTION_SETUP.md for detailed instructions"
    exit 1
fi

# Check if google-services.json exists
if [ ! -f "$ANDROID_DIR/app/google-services.json" ]; then
    echo -e "${RED}Error: google-services.json not found${NC}"
    echo "Please download it from Firebase Console and place it in:"
    echo "  android/app/google-services.json"
    echo ""
    echo "See FIREBASE_DISTRIBUTION_SETUP.md for detailed instructions"
    exit 1
fi

# Parse arguments
RELEASE_NOTES="${1:-New build from fastlane}"
TESTER_GROUPS="${2:-android-testers}"
TESTER_EMAILS="${3:-}"

echo -e "${GREEN}🚀 Starting Firebase App Distribution${NC}"
echo -e "${YELLOW}Release Notes:${NC} $RELEASE_NOTES"
if [ -n "$TESTER_GROUPS" ]; then
    echo -e "${YELLOW}Groups:${NC} $TESTER_GROUPS"
fi
if [ -n "$TESTER_EMAILS" ]; then
    echo -e "${YELLOW}Testers:${NC} $TESTER_EMAILS"
fi
echo ""

# ---------------------------------------------------------------------------
# TEMPORARY WORKAROUND: purchases_ui_flutter MapHelper K2 compiler bug
# @file:JvmSynthetic on an internal object breaks Kotlin 2.x K2 compiler —
# the class becomes invisible within the same module. Remove the annotation
# before each build. Safe to remove: `internal` already prevents Java access.
# Track fix: https://github.com/RevenueCat/purchases-flutter/issues
# ---------------------------------------------------------------------------
MAPHELPER_PATH="$HOME/.pub-cache/hosted/pub.dev/purchases_ui_flutter-9.13.1/android/src/main/kotlin/com/revenuecat/purchases_ui_flutter/MapHelper.kt"
if [ -f "$MAPHELPER_PATH" ]; then
    sed -i '' '/@file:JvmSynthetic/d' "$MAPHELPER_PATH"
    sed -i '' '/@JvmSynthetic/d' "$MAPHELPER_PATH"
    echo -e "${YELLOW}[workaround] Patched purchases_ui_flutter MapHelper.kt${NC}"
fi
# ---------------------------------------------------------------------------

# Navigate to android directory
cd "$ANDROID_DIR"

# Run fastlane distribution
echo -e "${GREEN}📦 Building and distributing...${NC}"
if [ -n "$TESTER_EMAILS" ]; then
    bundle exec fastlane distribute_firebase_with_notes notes:"$RELEASE_NOTES" testers:"$TESTER_EMAILS"
elif [ -n "$TESTER_GROUPS" ]; then
    bundle exec fastlane distribute_firebase_with_notes notes:"$RELEASE_NOTES" groups:"$TESTER_GROUPS"
else
    bundle exec fastlane distribute_firebase_with_notes notes:"$RELEASE_NOTES"
fi

# Check if successful
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Distribution successful!${NC}"
    if [ -n "$GROUPS" ] || [ -n "$TESTERS" ]; then
        echo -e "${YELLOW}Testers will receive an email notification.${NC}"
    fi
else
    echo ""
    echo -e "${RED}❌ Distribution failed!${NC}"
    echo "Check the error messages above for details."
    exit 1
fi
