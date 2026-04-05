#!/bin/bash

# ---------------------------------------------------------------------------
# Workaround: purchases_ui_flutter MapHelper K2 compiler bug
#
# @file:JvmSynthetic on an internal object breaks Kotlin 2.x K2 compiler —
# the object becomes invisible within the same module. Removing the annotation
# is safe: `internal` already prevents Java access.
#
# Track fix: https://github.com/RevenueCat/purchases-flutter/issues
# ---------------------------------------------------------------------------

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PURCHASES_UI_VERSION="${1:-9.13.1}"
MAPHELPER_PATH="$HOME/.pub-cache/hosted/pub.dev/purchases_ui_flutter-${PURCHASES_UI_VERSION}/android/src/main/kotlin/com/revenuecat/purchases_ui_flutter/MapHelper.kt"

if [ ! -f "$MAPHELPER_PATH" ]; then
    echo -e "${YELLOW}[patch_revenuecat_k2] MapHelper.kt not found at: $MAPHELPER_PATH — skipping${NC}"
    exit 0
fi

sed -i '' '/@file:JvmSynthetic/d' "$MAPHELPER_PATH"
sed -i '' '/@JvmSynthetic/d' "$MAPHELPER_PATH"
echo -e "${GREEN}[patch_revenuecat_k2] Patched purchases_ui_flutter-${PURCHASES_UI_VERSION} MapHelper.kt${NC}"
