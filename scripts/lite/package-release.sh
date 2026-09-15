#!/bin/bash

set -euo pipefail

readonly REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly RELEASE_TAG="${1:-${RELEASE_TAG:-}}"
readonly SIGNING_IDENTITY="${LOCAL_APP_SIGNING_IDENTITY:-Local Mac App Code Signing}"
readonly DERIVED_DATA_PATH="${EASYDICT_LITE_DERIVED_DATA:-${RUNNER_TEMP:-/tmp}/EasydictLiteDerivedData}"
readonly SOURCE_APP="$DERIVED_DATA_PATH/Build/Products/Release/Easydict Lite.app"
readonly EXECUTABLE_PATH="$SOURCE_APP/Contents/MacOS/Easydict Lite"
readonly ARTIFACT_DIRECTORY="$REPOSITORY_ROOT/dist"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: required command not found: $1" >&2
        exit 1
    fi
}

for command_name in codesign ditto hdiutil lipo security shasum xcodebuild; do
    require_command "$command_name"
done

if [[ ! "$RELEASE_TAG" =~ ^v([0-9]+\.[0-9]+\.[0-9]+)-lite\.([0-9]+)$ ]]; then
    echo "error: release tag must match v<version>-lite.<number>: $RELEASE_TAG" >&2
    exit 1
fi

readonly APP_VERSION="${BASH_REMATCH[1]}"
readonly LITE_VERSION="${BASH_REMATCH[2]}"
readonly DMG_PATH="$ARTIFACT_DIRECTORY/Easydict-Lite-$APP_VERSION-arm64.dmg"
readonly CHECKSUM_PATH="$DMG_PATH.sha256"

if ! security find-identity -v -p codesigning 2>/dev/null \
    | grep -F "\"${SIGNING_IDENTITY}\"" >/dev/null; then
    echo "error: signing identity not found: $SIGNING_IDENTITY" >&2
    exit 1
fi

xcodebuild build \
    -workspace "$REPOSITORY_ROOT/Easydict.xcworkspace" \
    -scheme Easydict \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_ALLOWED=NO \
    -quiet

if [[ ! -d "$SOURCE_APP" ]]; then
    echo "error: built app not found: $SOURCE_APP" >&2
    exit 1
fi

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$SOURCE_APP/Contents/Info.plist")"
built_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$SOURCE_APP/Contents/Info.plist")"
architectures="$(lipo -archs "$EXECUTABLE_PATH")"

if [[ "$bundle_id" != "com.anonymxxx.EasydictLite" ]]; then
    echo "error: unexpected bundle identifier: $bundle_id" >&2
    exit 1
fi
if [[ "$built_version" != "$APP_VERSION" ]]; then
    echo "error: tag version $APP_VERSION differs from app version $built_version" >&2
    exit 1
fi
if [[ "$architectures" != "arm64" ]]; then
    echo "error: release executable must be arm64, got: $architectures" >&2
    exit 1
fi

codesign \
    --force \
    --deep \
    --sign "$SIGNING_IDENTITY" \
    --timestamp=none \
    "$SOURCE_APP"
codesign --verify --deep --strict "$SOURCE_APP"

designated_requirement="$({ codesign -d -r- "$SOURCE_APP" 2>&1 || true; } \
    | sed -n 's/^#* *designated => //p')"
if [[ -z "$designated_requirement" || "$designated_requirement" == cdhash* ]]; then
    echo "error: signing did not produce a stable designated requirement" >&2
    exit 1
fi

if [[ -d "$ARTIFACT_DIRECTORY" ]]; then
    rm -rf "$ARTIFACT_DIRECTORY"
fi
mkdir -p "$ARTIFACT_DIRECTORY"

staging_directory="$(mktemp -d "${RUNNER_TEMP:-/tmp}/easydict-lite-dmg.XXXXXX")"
cleanup() {
    rm -rf "$staging_directory"
}
trap cleanup EXIT

ditto "$SOURCE_APP" "$staging_directory/Easydict Lite.app"
ln -s /Applications "$staging_directory/Applications"

hdiutil create \
    -volname "Easydict Lite $APP_VERSION" \
    -srcfolder "$staging_directory" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none "$DMG_PATH"
codesign --verify --strict "$DMG_PATH"
hdiutil verify "$DMG_PATH" >/dev/null

checksum="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
printf '%s  %s\n' "$checksum" "$(basename "$DMG_PATH")" > "$CHECKSUM_PATH"

echo "Release tag: $RELEASE_TAG"
echo "Release title: Easydict Lite $APP_VERSION (Lite $LITE_VERSION)"
echo "Application: $APP_VERSION ($(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$SOURCE_APP/Contents/Info.plist"))"
echo "Architecture: $architectures"
echo "Designated requirement: $designated_requirement"
echo "DMG: $DMG_PATH"
echo "SHA-256: $checksum"
