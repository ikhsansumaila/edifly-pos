#!/bin/bash

# ============================================
# Edifly POS - Build Script
# ============================================
# Usage:
#   ./build.sh [mode] [increment] [stage]
#
# Modes:
#   debug   - Build debug APK
#   release - Build release APK
#   both    - Build both debug and release
#
# Increment (optional):
#   none    - No version increment (default)
#   build   - Increment build number (0.0.4+1 → 0.0.4+2)
#   patch   - Increment patch version (0.0.4 → 0.0.5)
#   minor   - Increment minor version (0.0.4 → 0.1.0)
#   major   - Increment major version (0.0.4 → 1.0.0)
#
# Stage (optional):
#   dev     - Development version (0.0.4-dev)
#   alpha   - Alpha version (0.0.4-alpha)
#   beta    - Beta version (0.0.4-beta)
#   rc      - Release candidate (0.0.4-rc)
#   prod    - Production version (0.0.4) - no suffix
#   keep    - Keep current stage (default)
#
# Examples:
#   ./build.sh debug                    # Build debug tanpa increment
#   ./build.sh release patch            # Build release + increment patch
#   ./build.sh release patch dev        # Build release + increment patch + set ke dev
#   ./build.sh both build beta          # Build keduanya + increment build + set ke beta
#   ./build.sh release none prod        # Build release + set ke production (hapus suffix)
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBSPEC_FILE="$SCRIPT_DIR/pubspec.yaml"
OUTPUT_DIR="$SCRIPT_DIR/build/app/outputs/flutter-apk"

# Default values
BUILD_MODE="${1:-debug}"
INCREMENT_TYPE="${2:-none}"
STAGE="${3:-keep}"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_stage() {
    local stage="$1"
    case "$stage" in
        dev)
            echo -e "${PURPLE}[DEV]${NC}"
            ;;
        alpha)
            echo -e "${CYAN}[ALPHA]${NC}"
            ;;
        beta)
            echo -e "${YELLOW}[BETA]${NC}"
            ;;
        rc)
            echo -e "${BLUE}[RC]${NC}"
            ;;
        prod|"")
            echo -e "${GREEN}[PROD]${NC}"
            ;;
    esac
}

# Function to get current version from pubspec.yaml
get_current_version() {
    grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //'
}

# Function to parse version components
# Supports: 0.0.4+1, 0.0.4-dev+1, 0.0.4-beta+1, etc.
parse_version() {
    local full_version="$1"
    
    # Split by + to get version and build number
    local version_with_stage=$(echo "$full_version" | cut -d'+' -f1)
    BUILD_NUMBER=$(echo "$full_version" | cut -d'+' -f2)
    
    # If no build number, default to 1
    if [ "$version_with_stage" == "$BUILD_NUMBER" ]; then
        BUILD_NUMBER=1
    fi
    
    # Check if there's a stage suffix (e.g., -dev, -beta)
    if [[ "$version_with_stage" == *"-"* ]]; then
        VERSION_PART=$(echo "$version_with_stage" | cut -d'-' -f1)
        CURRENT_STAGE=$(echo "$version_with_stage" | cut -d'-' -f2)
    else
        VERSION_PART="$version_with_stage"
        CURRENT_STAGE=""
    fi
    
    # Split version part by .
    MAJOR=$(echo "$VERSION_PART" | cut -d'.' -f1)
    MINOR=$(echo "$VERSION_PART" | cut -d'.' -f2)
    PATCH=$(echo "$VERSION_PART" | cut -d'.' -f3)
}

# Function to increment version
increment_version() {
    local increment_type="$1"
    
    case "$increment_type" in
        build)
            BUILD_NUMBER=$((BUILD_NUMBER + 1))
            ;;
        patch)
            PATCH=$((PATCH + 1))
            BUILD_NUMBER=$((BUILD_NUMBER + 1))
            ;;
        minor)
            MINOR=$((MINOR + 1))
            PATCH=0
            BUILD_NUMBER=$((BUILD_NUMBER + 1))
            ;;
        major)
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            BUILD_NUMBER=$((BUILD_NUMBER + 1))
            ;;
        none)
            # No increment
            ;;
        *)
            print_error "Unknown increment type: $increment_type"
            exit 1
            ;;
    esac
}

# Function to set stage
set_stage() {
    local stage="$1"
    
    case "$stage" in
        dev|alpha|beta|rc)
            CURRENT_STAGE="$stage"
            ;;
        prod)
            CURRENT_STAGE=""
            ;;
        keep)
            # Keep current stage
            ;;
        *)
            print_error "Unknown stage: $stage"
            echo "Valid stages: dev, alpha, beta, rc, prod, keep"
            exit 1
            ;;
    esac
}

# Function to build new version string
build_version_string() {
    if [ -n "$CURRENT_STAGE" ]; then
        NEW_VERSION="$MAJOR.$MINOR.$PATCH-$CURRENT_STAGE+$BUILD_NUMBER"
        NEW_VERSION_DISPLAY="$MAJOR.$MINOR.$PATCH-$CURRENT_STAGE"
    else
        NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD_NUMBER"
        NEW_VERSION_DISPLAY="$MAJOR.$MINOR.$PATCH"
    fi
}

# Function to update pubspec.yaml with new version
update_pubspec_version() {
    local new_version="$1"
    
    # Use sed to replace version line
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^version: .*/version: $new_version/" "$PUBSPEC_FILE"
    else
        # Linux
        sed -i "s/^version: .*/version: $new_version/" "$PUBSPEC_FILE"
    fi
}

# Function to build APK
build_apk() {
    local mode="$1"
    
    print_info "Building $mode APK..."
    
    cd "$SCRIPT_DIR"
    flutter build apk --$mode
    
    if [ $? -eq 0 ]; then
        print_success "Build $mode berhasil!"
    else
        print_error "Build $mode gagal!"
        exit 1
    fi
}

# Function to show build result
show_result() {
    local stage_display=$(print_stage "$CURRENT_STAGE")
    
    echo ""
    echo "============================================"
    echo -e "${GREEN}🎉 BUILD SELESAI!${NC} $stage_display"
    echo "============================================"
    echo ""
    echo -e "📌 Versi: ${CYAN}$NEW_VERSION${NC}"
    echo ""
    
    if [ "$BUILD_MODE" == "debug" ] || [ "$BUILD_MODE" == "both" ]; then
        local debug_file="$OUTPUT_DIR/edifly-pos-v${NEW_VERSION_DISPLAY}-debug.apk"
        if [ -f "$debug_file" ]; then
            local debug_size=$(du -h "$debug_file" | cut -f1)
            echo -e "📦 ${YELLOW}Debug APK:${NC}"
            echo "   File: edifly-pos-v${NEW_VERSION_DISPLAY}-debug.apk"
            echo "   Size: $debug_size"
            echo "   Path: $debug_file"
            echo ""
        fi
    fi
    
    if [ "$BUILD_MODE" == "release" ] || [ "$BUILD_MODE" == "both" ]; then
        local release_file="$OUTPUT_DIR/edifly-pos-v${NEW_VERSION_DISPLAY}-release.apk"
        if [ -f "$release_file" ]; then
            local release_size=$(du -h "$release_file" | cut -f1)
            echo -e "📦 ${GREEN}Release APK:${NC}"
            echo "   File: edifly-pos-v${NEW_VERSION_DISPLAY}-release.apk"
            echo "   Size: $release_size"
            echo "   Path: $release_file"
            echo ""
        fi
    fi
    
    echo "============================================"
}

# Main script
main() {
    echo ""
    echo "============================================"
    echo -e "${BLUE}🚀 EDIFLY POS - BUILD SCRIPT${NC}"
    echo "============================================"
    echo ""
    
    # Validate build mode
    if [[ ! "$BUILD_MODE" =~ ^(debug|release|both)$ ]]; then
        print_error "Invalid build mode: $BUILD_MODE"
        echo "Valid modes: debug, release, both"
        exit 1
    fi
    
    # Validate increment type
    if [[ ! "$INCREMENT_TYPE" =~ ^(none|build|patch|minor|major)$ ]]; then
        print_error "Invalid increment type: $INCREMENT_TYPE"
        echo "Valid types: none, build, patch, minor, major"
        exit 1
    fi
    
    # Validate stage
    if [[ ! "$STAGE" =~ ^(dev|alpha|beta|rc|prod|keep)$ ]]; then
        print_error "Invalid stage: $STAGE"
        echo "Valid stages: dev, alpha, beta, rc, prod, keep"
        exit 1
    fi
    
    # Get and parse current version
    CURRENT_VERSION=$(get_current_version)
    parse_version "$CURRENT_VERSION"
    
    print_info "Versi saat ini: $CURRENT_VERSION"
    
    # Show current stage
    if [ -n "$CURRENT_STAGE" ]; then
        echo -e "   Stage: ${PURPLE}$CURRENT_STAGE${NC}"
    else
        echo -e "   Stage: ${GREEN}production${NC}"
    fi
    
    # Increment version if requested
    if [ "$INCREMENT_TYPE" != "none" ]; then
        increment_version "$INCREMENT_TYPE"
        print_info "Increment: $INCREMENT_TYPE"
    fi
    
    # Set stage if requested
    if [ "$STAGE" != "keep" ]; then
        set_stage "$STAGE"
        print_info "Stage: $STAGE"
    fi
    
    # Build version string
    build_version_string
    
    if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
        print_info "Versi baru: $NEW_VERSION"
        
        # Update pubspec.yaml
        update_pubspec_version "$NEW_VERSION"
        print_success "pubspec.yaml diupdate ke versi $NEW_VERSION"
    else
        print_info "Tidak ada perubahan versi"
    fi
    
    echo ""
    print_info "Build mode: $BUILD_MODE"
    echo ""
    
    # Build based on mode
    case "$BUILD_MODE" in
        debug)
            build_apk "debug"
            ;;
        release)
            build_apk "release"
            ;;
        both)
            build_apk "debug"
            echo ""
            build_apk "release"
            ;;
    esac
    
    # Show result
    show_result
}

# Show help
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo ""
    echo "Usage: ./build.sh [mode] [increment] [stage]"
    echo ""
    echo "Modes:"
    echo "  debug   - Build debug APK"
    echo "  release - Build release APK"
    echo "  both    - Build both debug and release"
    echo ""
    echo "Increment (optional):"
    echo "  none    - No version increment (default)"
    echo "  build   - Increment build number (0.0.4+1 → 0.0.4+2)"
    echo "  patch   - Increment patch version (0.0.4 → 0.0.5)"
    echo "  minor   - Increment minor version (0.0.4 → 0.1.0)"
    echo "  major   - Increment major version (0.0.4 → 1.0.0)"
    echo ""
    echo "Stage (optional):"
    echo "  dev     - Development version (0.0.4-dev)"
    echo "  alpha   - Alpha version (0.0.4-alpha)"
    echo "  beta    - Beta version (0.0.4-beta)"
    echo "  rc      - Release candidate (0.0.4-rc)"
    echo "  prod    - Production version (0.0.4) - removes suffix"
    echo "  keep    - Keep current stage (default)"
    echo ""
    echo "Examples:"
    echo "  ./build.sh debug                    # Build debug tanpa increment"
    echo "  ./build.sh release patch            # Build release + increment patch"
    echo "  ./build.sh release patch dev        # Build release + patch + set dev stage"
    echo "  ./build.sh both build beta          # Build both + build number + set beta"
    echo "  ./build.sh release none prod        # Build release + set to production"
    echo ""
    echo "Version Flow Example:"
    echo "  0.0.4-dev+1  →  ./build.sh release patch dev   →  0.0.5-dev+2"
    echo "  0.0.5-dev+2  →  ./build.sh release none beta   →  0.0.5-beta+2"
    echo "  0.0.5-beta+2 →  ./build.sh release build rc    →  0.0.5-rc+3"
    echo "  0.0.5-rc+3   →  ./build.sh release none prod   →  0.0.5+3"
    echo ""
    exit 0
fi

# Run main
main
