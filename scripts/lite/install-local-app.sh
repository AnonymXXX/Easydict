#!/bin/bash

set -euo pipefail

readonly IDENTITY_NAME="${LOCAL_APP_SIGNING_IDENTITY:-Local Mac App Code Signing}"
readonly EXPECTED_BUNDLE_ID="com.anonymxxx.EasydictLite"
readonly DEFAULT_SOURCE_APP="/tmp/EasydictLiteDerivedData/Build/Products/Release/Easydict Lite.app"
readonly SOURCE_APP="${1:-$DEFAULT_SOURCE_APP}"
readonly INSTALLED_APP="/Applications/Easydict Lite.app"
readonly EXECUTABLE_NAME="Easydict Lite"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: required command not found: $1" >&2
        exit 1
    fi
}

require_command codesign
require_command ditto
require_command open
require_command osascript
require_command pgrep
require_command security
require_command shasum

if [[ ! -d "$SOURCE_APP" ]]; then
    echo "error: source app not found: $SOURCE_APP" >&2
    exit 1
fi

source_bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$SOURCE_APP/Contents/Info.plist")"
if [[ "$source_bundle_id" != "$EXPECTED_BUNDLE_ID" ]]; then
    echo "error: unexpected source bundle id: $source_bundle_id" >&2
    exit 1
fi

if ! security find-identity -v -p codesigning 2>/dev/null \
    | grep -F "\"${IDENTITY_NAME}\"" >/dev/null; then
    echo "error: signing identity not found: $IDENTITY_NAME" >&2
    echo "run scripts/lite/setup-local-signing.sh first" >&2
    exit 1
fi

codesign \
    --force \
    --deep \
    --sign "$IDENTITY_NAME" \
    --timestamp=none \
    "$SOURCE_APP"
codesign --verify --deep --strict "$SOURCE_APP"

designated_requirement="$(
    codesign -d -r- "$SOURCE_APP" 2>&1 \
        | sed -n 's/^#* *designated => //p'
)"
if [[ -z "$designated_requirement" || "$designated_requirement" == cdhash* ]]; then
    echo "error: signing did not produce a stable designated requirement" >&2
    exit 1
fi

osascript -e 'tell application id "com.anonymxxx.EasydictLite" to quit' 2>/dev/null || true
for _ in {1..20}; do
    if ! pgrep -f '/Applications/Easydict Lite.app/Contents/MacOS/Easydict Lite' >/dev/null; then
        break
    fi
    sleep 0.25
done

if pgrep -f '/Applications/Easydict Lite.app/Contents/MacOS/Easydict Lite' >/dev/null; then
    echo "error: installed app did not quit" >&2
    exit 1
fi

if [[ -d "$INSTALLED_APP" ]]; then
    installed_bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INSTALLED_APP/Contents/Info.plist")"
    if [[ "$installed_bundle_id" != "$EXPECTED_BUNDLE_ID" ]]; then
        echo "error: refusing to replace unexpected app: $INSTALLED_APP" >&2
        exit 1
    fi
    /usr/bin/trash "$INSTALLED_APP"
fi

ditto "$SOURCE_APP" "$INSTALLED_APP"
codesign --verify --deep --strict "$INSTALLED_APP"

source_hash="$(shasum -a 256 "$SOURCE_APP/Contents/MacOS/$EXECUTABLE_NAME" | awk '{print $1}')"
installed_hash="$(shasum -a 256 "$INSTALLED_APP/Contents/MacOS/$EXECUTABLE_NAME" | awk '{print $1}')"
if [[ "$source_hash" != "$installed_hash" ]]; then
    echo "error: installed executable hash does not match source" >&2
    exit 1
fi

open -a "$INSTALLED_APP"
for _ in {1..20}; do
    if pgrep -f '/Applications/Easydict Lite.app/Contents/MacOS/Easydict Lite' >/dev/null; then
        break
    fi
    sleep 0.25
done

if ! pgrep -f '/Applications/Easydict Lite.app/Contents/MacOS/Easydict Lite' >/dev/null; then
    echo "error: installed app did not start" >&2
    exit 1
fi

echo "Installed: $INSTALLED_APP"
echo "Signing identity: $IDENTITY_NAME"
echo "Designated requirement: $designated_requirement"
echo "Executable SHA-256: $installed_hash"
