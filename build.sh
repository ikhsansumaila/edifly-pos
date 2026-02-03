#!/bin/bash

# ============================================
# Edifly POS - Smart Build Script
# ============================================
# Usage:
#   ./build.sh [mode] [increment] [stage] [target_version]
#
# Key Features:
#   - Separate version history for DEV and PROD
#   - Auto-switch API URLs
#   - Auto-update App Name (POS Retail vs POS Retail (DEV))
#   - Auto-clean project
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBSPEC_FILE="$SCRIPT_DIR/pubspec.yaml"
API_CONFIG_FILE="$SCRIPT_DIR/lib/core/network/api_config.dart"
OUTPUT_DIR="$SCRIPT_DIR/build/app/outputs/flutter-apk"

# App Config
BASE_APP_NAME="Dimonggoin Kasir"
ANDROID_MANIFEST="$SCRIPT_DIR/android/app/src/main/AndroidManifest.xml"
IOS_INFO_PLIST="$SCRIPT_DIR/ios/Runner/Info.plist"

# Version History Storage
VERSION_DIR="$SCRIPT_DIR/.build_versions"
mkdir -p "$VERSION_DIR"
DEV_VERSION_FILE="$VERSION_DIR/dev_version"
PROD_VERSION_FILE="$VERSION_DIR/prod_version"

# API URLs
DEV_API_URL="https://prototype.edifly-dev.com/pos/api"
PROD_API_URL="https://pos.avconindonesia.com/api"

# Default Arguments
BUILD_MODE="${1:-debug}"
INCREMENT_TYPE="${2:-none}"
STAGE="${3:-keep}"
TARGET_VERSION="${4:-}"

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

get_pubspec_version() {
    grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //'
}

parse_version() {
    local full_version="$1"
    
    local version_with_stage=$(echo "$full_version" | cut -d'+' -f1)
    BUILD_NUMBER=$(echo "$full_version" | cut -d'+' -f2 -s)
    
    if [ -z "$BUILD_NUMBER" ]; then BUILD_NUMBER=1; fi
    
    if [[ "$version_with_stage" == *"-"* ]]; then
        VERSION_PART=$(echo "$version_with_stage" | cut -d'-' -f1)
        CURRENT_STAGE=$(echo "$version_with_stage" | cut -d'-' -f2)
    else
        VERSION_PART="$version_with_stage"
        CURRENT_STAGE=""
    fi
    
    MAJOR=$(echo "$VERSION_PART" | cut -d'.' -f1)
    MINOR=$(echo "$VERSION_PART" | cut -d'.' -f2)
    PATCH=$(echo "$VERSION_PART" | cut -d'.' -f3)
}

build_version_string() {
    if [ -n "$CURRENT_STAGE" ]; then
        NEW_VERSION="$MAJOR.$MINOR.$PATCH-$CURRENT_STAGE+$BUILD_NUMBER"
        NEW_VERSION_DISPLAY="$MAJOR.$MINOR.$PATCH-$CURRENT_STAGE"
    else
        NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD_NUMBER"
        NEW_VERSION_DISPLAY="$MAJOR.$MINOR.$PATCH"
    fi
}

increment_version() {
    local type="$1"
    case "$type" in
        build) BUILD_NUMBER=$((BUILD_NUMBER + 1)) ;;
        patch) PATCH=$((PATCH + 1)); BUILD_NUMBER=$((BUILD_NUMBER + 1)) ;;
        minor) MINOR=$((MINOR + 1)); PATCH=0; BUILD_NUMBER=$((BUILD_NUMBER + 1)) ;;
        major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0; BUILD_NUMBER=$((BUILD_NUMBER + 1)) ;;
        none) ;;
        *) print_error "Unknown increment type: $type"; exit 1 ;;
    esac
}

update_pubspec_version() {
    local new_ver="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^version: .*/version: $new_ver/" "$PUBSPEC_FILE"
    else
        sed -i "s/^version: .*/version: $new_ver/" "$PUBSPEC_FILE"
    fi
}

update_api_config() {
    local track="$1"
    local stage_name="$2"
    
    local target_url=""
    local mode_name=""

    if [ "$track" == "prod" ]; then
        target_url="$PROD_API_URL"
        mode_name="PRODUCTION"
    else
        target_url="$DEV_API_URL"
        mode_name="DEVELOPMENT ($stage_name)"
    fi

    print_info "Set API untuk $mode_name"
    echo "const API_BASE_URL = '$target_url';" > "$API_CONFIG_FILE"
}

update_app_name() {
    local track="$1"
    local stage_name="$2"
    local new_name="$BASE_APP_NAME"
    
    # If not production, append stage (e.g., DEV, ALPHA)
    if [ "$track" != "prod" ]; then
         if [ -n "$stage_name" ]; then
             local stage_upper=$(echo "$stage_name" | tr '[:lower:]' '[:upper:]')
             new_name="$BASE_APP_NAME ($stage_upper)"
         else
             new_name="$BASE_APP_NAME (DEV)"
         fi
    fi
    
    print_info "Update App Name: $new_name"
    
    # Update Android Manifest and iOS Info.plist
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/android:label=\".*\"/android:label=\"$new_name\"/" "$ANDROID_MANIFEST"
        sed -i '' "/CFBundleDisplayName/{n;s/<string>.*<\/string>/<string>$new_name<\/string>/;}" "$IOS_INFO_PLIST"
    else
        sed -i "s/android:label=\".*\"/android:label=\"$new_name\"/" "$ANDROID_MANIFEST"
        sed -i "/CFBundleDisplayName/{n;s/<string>.*<\/string>/<string>$new_name<\/string>/;}" "$IOS_INFO_PLIST"
    fi
}

# ==============================================================================
# MAIN LOGIC
# ==============================================================================

main() {
    echo ""
    echo "============================================"
    echo -e "${BLUE}🚀 EDIFLY POS - SMART BUILD${NC}"
    echo "============================================"
    echo ""

    # 1. Determine TRACK
    TRACK=""
    EFFECTIVE_STAGE=""
    
    PUBSPEC_VER=$(get_pubspec_version)
    
    if [[ "$STAGE" =~ ^(dev|alpha|beta|rc)$ ]]; then
        TRACK="dev"
        EFFECTIVE_STAGE="$STAGE"
    elif [[ "$STAGE" == "prod" ]]; then
        TRACK="prod"
        EFFECTIVE_STAGE=""
    elif [[ "$STAGE" == "keep" ]]; then
        if [[ "$PUBSPEC_VER" == *"-"* ]]; then
            TRACK="dev"
            EFFECTIVE_STAGE=$(echo "$PUBSPEC_VER" | cut -d'-' -f2 | cut -d'+' -f1)
        else
            TRACK="prod"
            EFFECTIVE_STAGE=""
        fi
        print_info "Auto-detect track: $TRACK"
    else
        print_error "Invalid stage: $STAGE"
        exit 1
    fi

    # 2. Select Version File
    if [ "$TRACK" == "prod" ]; then
        TRACK_FILE="$PROD_VERSION_FILE"
    else
        TRACK_FILE="$DEV_VERSION_FILE"
    fi

    # 3. Read Start Version
    START_VERSION=""
    
    if [ -n "$TARGET_VERSION" ]; then
        print_info "Using Manual Target Version: $TARGET_VERSION"
        START_VERSION="$TARGET_VERSION"
    elif [ -f "$TRACK_FILE" ]; then
        START_VERSION=$(cat "$TRACK_FILE")
        print_info "Loaded stored $TRACK version: $START_VERSION"
    else
        parse_version "$PUBSPEC_VER"
        
        if [ "$TRACK" == "prod" ]; then
            CURRENT_STAGE="" 
        elif [ "$TRACK" == "dev" ] && [ -z "$CURRENT_STAGE" ]; then
            CURRENT_STAGE="dev"
        fi
        
        build_version_string
        START_VERSION="$NEW_VERSION"
        print_warning "No stored version for $TRACK. Initializing from pubspec: $START_VERSION"
    fi

    # 4. Process Increment
    parse_version "$START_VERSION"
    
    if [ "$STAGE" != "keep" ]; then
         CURRENT_STAGE="$EFFECTIVE_STAGE"
    fi
    
    if [ "$INCREMENT_TYPE" != "none" ]; then
        increment_version "$INCREMENT_TYPE"
        print_info "Incrementing detected: $INCREMENT_TYPE"
    fi

    # 5. Build Final String & Save
    build_version_string
    
    echo "$NEW_VERSION" > "$TRACK_FILE"
    
    if [ "$PUBSPEC_VER" != "$NEW_VERSION" ]; then
        update_pubspec_version "$NEW_VERSION"
        print_success "Pubspec updated: $NEW_VERSION"
    else
        print_info "Version unchanged"
    fi
    
    echo -e "Saved to history: ${BLUE}$TRACK_FILE${NC}"

    # 6. Config Updates (API, App Name) & Clean
    echo ""
    update_api_config "$TRACK" "$CURRENT_STAGE"
    update_app_name "$TRACK" "$CURRENT_STAGE"
    
    echo ""
    print_info "Cleaning project..."
    flutter clean > /dev/null
    flutter pub get > /dev/null
    print_success "Clean & Pub Get done"

    # 7. Build
    echo ""
    print_info "Building ($BUILD_MODE)..."
    
    cd "$SCRIPT_DIR"
    
    if [ "$BUILD_MODE" == "both" ]; then
        flutter build apk --debug
        flutter build apk --release
    else
        flutter build apk --$BUILD_MODE
    fi

    # 8. Result
    echo ""
    echo "============================================"
    echo "🎉 VERSION: $NEW_VERSION"
    echo "============================================"
    if [[ "$BUILD_MODE" =~ (release|both) ]]; then
        echo -e "📦 Release: build/app/outputs/flutter-apk/app-release.apk"
    fi
    if [[ "$BUILD_MODE" =~ (debug|both) ]]; then
        echo -e "📦 Debug:   build/app/outputs/flutter-apk/app-debug.apk"
    fi
}

main
