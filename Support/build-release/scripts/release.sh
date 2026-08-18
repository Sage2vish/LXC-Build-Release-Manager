#!/bin/bash
set -euo pipefail

# Builds the Release configuration, stages a .dmg, and optionally publishes it as a GitHub
# Release asset.
#
# The .dmg is deliberately NOT committed to git — `version/` and `*.dmg` are ignored. Binaries
# belong in GitHub Releases, which is also where the in-app update checker looks. Committing
# them would grow the repository permanently for no benefit.
#
#   ./release.sh                      build and stage the .dmg locally
#   ./release.sh --publish            also publish it as a GitHub Release
#   ./release.sh --publish --prerelease   publish it to the Beta channel
#
# Publishing needs the GitHub CLI, authenticated: https://cli.github.com

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_RELEASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$BUILD_RELEASE_DIR/../.." && pwd)"
DERIVED_DATA_DIR="$PROJECT_ROOT/.derivedData"
APP_NAME="LXC-Build-Release-Manager"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release/$APP_NAME.app"
STAGING_DIR="$BUILD_RELEASE_DIR/version/staging"
DMG_BACKGROUND="$BUILD_RELEASE_DIR/../context/concepts-designs/Back-Images/ui-back-main.png"
DMG_VOLUME_ICON="$APP_PATH/Contents/Resources/AppIcon.icns"
DMG_README="$BUILD_RELEASE_DIR/version/DMG-README.txt"

PUBLISH=false
PRERELEASE=false
for arg in "$@"; do
  case "$arg" in
    --publish) PUBLISH=true ;;
    --prerelease) PRERELEASE=true ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

echo "Building Release configuration for $APP_NAME"
xcodebuild \
  -project "$PROJECT_ROOT/LXC-Build-Release-Manager.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

if [ ! -d "$APP_PATH" ]; then
  echo "Expected app bundle not found at $APP_PATH" >&2
  exit 1
fi

# Take the version from the built app rather than a date. The in-app update checker compares
# release tags against CFBundleShortVersionString, so the artifact has to carry that version.
VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")"
if [ -z "$VERSION" ]; then
  echo "Could not read CFBundleShortVersionString from the built app" >&2
  exit 1
fi

DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$BUILD_RELEASE_DIR/version/$DMG_NAME"
TAG="v$VERSION"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
if [ -f "$DMG_BACKGROUND" ]; then
  mkdir -p "$STAGING_DIR/.background"
  cp "$DMG_BACKGROUND" "$STAGING_DIR/.background/background.png"
fi
if [ -f "$DMG_VOLUME_ICON" ]; then
  cp "$DMG_VOLUME_ICON" "$STAGING_DIR/.VolumeIcon.icns"
  SetFile -a V "$STAGING_DIR/.VolumeIcon.icns" >/dev/null 2>&1 || true
fi
ln -s /Applications "$STAGING_DIR/Applications"
cat > "$DMG_README" <<'EOF'
Lexvora Consulting package

Website:
https://www.lexvoraconsulting.com/

This DMG contains:
- LXC-Build-Release-Manager.app
- Applications alias for drag-and-drop install
- branded background art

Install:
1. Open the DMG.
2. Drag the app to Applications.
3. Eject the disk image when done.
EOF
cp "$DMG_README" "$STAGING_DIR/DMG-README.txt"

echo "Creating DMG at $DMG_PATH"
rm -f "$DMG_PATH"
TMP_DMG_PATH="${DMG_PATH%.dmg}.temp.dmg"
rm -f "$TMP_DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDRW \
  "$TMP_DMG_PATH"

MOUNT_POINT="$(mktemp -d /tmp/lxc-brm-dmg.XXXXXX)"
cleanup() {
  hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
  rmdir "$MOUNT_POINT" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Configuring Finder presentation for $TMP_DMG_PATH"
hdiutil attach "$TMP_DMG_PATH" -mountpoint "$MOUNT_POINT" -nobrowse >/dev/null
python3 - "$MOUNT_POINT" "$APP_NAME" <<'PY'
from pathlib import Path
import sys

from ds_store import DSStore, DSStoreEntry
from ds_store.store import ILocCodec, PlistCodec
from mac_alias import Alias

mount_point = Path(sys.argv[1])
app_name = sys.argv[2]
store_path = mount_point / ".DS_Store"
background = mount_point / ".background" / "background.png"

entries = [
    DSStoreEntry(
        ".",
        "icvp",
        PlistCodec,
        {
            "backgroundType": 2,
            "backgroundImageAlias": Alias.for_file(str(background)).to_bytes(),
            "iconSize": 144,
            "textSize": 12,
            "showIconPreview": False,
            "arrangeBy": "none",
            "viewOptionsVersion": 1,
        },
    ),
    DSStoreEntry(f"{app_name}.app", "Iloc", ILocCodec, (220, 250)),
    DSStoreEntry("Applications", "Iloc", ILocCodec, (700, 250)),
    DSStoreEntry("DMG-README.txt", "Iloc", ILocCodec, (460, 530)),
]

with DSStore.open(str(store_path), "w+", entries):
    pass
PY
sync
if [ -f "$MOUNT_POINT/.VolumeIcon.icns" ]; then
  SetFile -a C "$MOUNT_POINT" >/dev/null 2>&1 || true
  SetFile -a V "$MOUNT_POINT/.VolumeIcon.icns" >/dev/null 2>&1 || true
fi
bless --folder "$MOUNT_POINT" --openfolder "$MOUNT_POINT" >/dev/null 2>&1 || true
hdiutil detach "$MOUNT_POINT" >/dev/null
trap - EXIT
rmdir "$MOUNT_POINT" >/dev/null 2>&1 || true

echo "Converting to final compressed DMG"
hdiutil convert "$TMP_DMG_PATH" -format UDZO -ov -o "$DMG_PATH" >/dev/null
rm -f "$TMP_DMG_PATH"
if [ -f "$DMG_VOLUME_ICON" ]; then
  TMP_SWIFT="$(mktemp /tmp/lxc-brm-dmg-icon.XXXXXX.swift)"
  cat > "$TMP_SWIFT" <<EOF
import AppKit
import Foundation

let dmgPath = URL(fileURLWithPath: "$DMG_PATH").path
let iconPath = URL(fileURLWithPath: "$DMG_VOLUME_ICON").path
if let icon = NSImage(contentsOfFile: iconPath) {
    let ok = NSWorkspace.shared.setIcon(icon, forFile: dmgPath, options: [])
    if !ok {
        fputs("Warning: could not set icon on \(dmgPath)\n", stderr)
    }
}
EOF
  swift "$TMP_SWIFT"
  rm -f "$TMP_SWIFT"
  SetFile -a C "$DMG_PATH" >/dev/null 2>&1 || true
fi

echo "Release artifact staged at $DMG_PATH (version $VERSION)"

if [ "$PUBLISH" != true ]; then
  echo
  echo "Not published. To publish this build so the in-app updater can see it:"
  echo "  $0 --publish"
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required to publish. Install it from https://cli.github.com" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login" >&2
  exit 1
fi

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "Release $TAG already exists; uploading the asset to it (replacing any existing copy)."
  gh release upload "$TAG" "$DMG_PATH" --clobber
else
  echo "Creating GitHub Release $TAG"
  PRERELEASE_FLAG=""
  if [ "$PRERELEASE" = true ]; then
    PRERELEASE_FLAG="--prerelease"
  fi
  # shellcheck disable=SC2086
  gh release create "$TAG" "$DMG_PATH" \
    --title "$VERSION" \
    --notes "Release $VERSION of $APP_NAME." \
    $PRERELEASE_FLAG
fi

echo
echo "Published $TAG. The in-app update checker reads this feed:"
echo "  https://api.github.com/repos/Sage2vish/LXC-Build-Release-Manager/releases"
if [ "$PRERELEASE" = true ]; then
  echo "Marked as a prerelease, so only the Beta channel will offer it."
else
  echo "Published as a stable release, so both channels will offer it."
fi
