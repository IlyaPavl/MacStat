#!/bin/zsh
# Builds a Release, ad-hoc signed MacStat.app and packs it into build/MacStat-<version>.dmg.
set -euo pipefail

cd "${0:A:h}"
BUILD_DIR="$PWD/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
STAGING="$BUILD_DIR/dmg"

rm -rf "$STAGING"
mkdir -p "$STAGING"

xcodebuild \
  -project MacStat.xcodeproj \
  -scheme MacStat \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM= \
  clean build > "$BUILD_DIR/build.log" 2>&1 \
  || { grep -E 'error' "$BUILD_DIR/build.log" >&2; echo "Build failed, see $BUILD_DIR/build.log" >&2; exit 1; }

APP="$DERIVED_DATA/Build/Products/Release/MacStat.app"
codesign --verify --strict "$APP"

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")
DMG="$BUILD_DIR/MacStat-$VERSION.dmg"

ditto "$APP" "$STAGING/MacStat.app"
ln -s /Applications "$STAGING/Applications"

rm -f "$DMG"
diskutil image create from --format ULMO --volumeName "MacStat" "$STAGING" "$DMG" >> "$BUILD_DIR/build.log" 2>&1 \
  || { echo "DMG creation failed, see $BUILD_DIR/build.log" >&2; exit 1; }
rm -rf "$STAGING"

echo "$DMG"
