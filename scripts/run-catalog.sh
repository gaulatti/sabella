#!/bin/sh
set -eu

platform="${1:-macos}"
repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

case "$platform" in
  macos)
    cd "$repository_root"
    swift run SabellaCatalog
    ;;
  ios)
    simulator_name="${SIMULATOR_NAME:-iPhone 17 Pro}"
    sdk_platform="iOS Simulator"
    sdk="iphonesimulator"
    family="1"
    ;;
  ipad)
    simulator_name="${SIMULATOR_NAME:-iPad Pro 13-inch (M5)}"
    sdk_platform="iOS Simulator"
    sdk="iphonesimulator"
    family="2"
    ;;
  tvos)
    simulator_name="${SIMULATOR_NAME:-Apple TV 4K (3rd generation)}"
    sdk_platform="tvOS Simulator"
    sdk="appletvsimulator"
    family="3"
    ;;
  *)
    echo "usage: $0 macos|ios|ipad|tvos" >&2
    exit 64
    ;;
esac

if [ "$platform" = "macos" ]; then
  exit 0
fi

derived_data="${DERIVED_DATA_PATH:-$repository_root/.build/catalog-$platform}"
simulator_id="${SIMULATOR_ID:-$(xcrun simctl list devices available -j | /usr/bin/python3 -c '
import json, sys
name = sys.argv[1]
devices = [device for runtime in json.load(sys.stdin)["devices"].values() for device in runtime if device["name"] == name]
if devices:
    print(devices[-1]["udid"])
' "$simulator_name")}"

if [ -z "$simulator_id" ]; then
  echo "No available simulator named '$simulator_name'. Set SIMULATOR_NAME or SIMULATOR_ID." >&2
  exit 69
fi

destination="platform=$sdk_platform,id=$simulator_id"

cd "$repository_root"
xcodebuild \
  -scheme SabellaCatalog \
  -destination "$destination" \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  build

executable="$derived_data/Build/Products/Debug-$sdk/SabellaCatalog"
resource_bundle="$derived_data/Build/Products/Debug-$sdk/Sabella_Sabella.bundle"
ksplayer_resource_bundle="$derived_data/Build/Products/Debug-$sdk/KSPlayer_KSPlayer.bundle"
app_bundle="$derived_data/SabellaCatalog.app"
bundle_identifier="com.gaulatti.sabella.catalog.$platform"

test -x "$executable"
test -d "$resource_bundle"
mkdir -p "$app_bundle"
cp "$executable" "$app_bundle/SabellaCatalog"
rm -rf "$app_bundle/Sabella_Sabella.bundle"
cp -R "$resource_bundle" "$app_bundle/Sabella_Sabella.bundle"
if [ "$platform" = "tvos" ]; then
  test -d "$ksplayer_resource_bundle"
  rm -rf "$app_bundle/KSPlayer_KSPlayer.bundle"
  cp -R "$ksplayer_resource_bundle" "$app_bundle/KSPlayer_KSPlayer.bundle"
fi

plutil -create xml1 "$app_bundle/Info.plist"
plutil -insert CFBundleDisplayName -string "Sabella Catalog" "$app_bundle/Info.plist"
plutil -insert CFBundleExecutable -string SabellaCatalog "$app_bundle/Info.plist"
plutil -insert CFBundleIdentifier -string "$bundle_identifier" "$app_bundle/Info.plist"
plutil -insert CFBundleName -string SabellaCatalog "$app_bundle/Info.plist"
plutil -insert CFBundlePackageType -string APPL "$app_bundle/Info.plist"
plutil -insert CFBundleShortVersionString -string 1.0 "$app_bundle/Info.plist"
plutil -insert CFBundleVersion -string 1 "$app_bundle/Info.plist"
plutil -insert LSRequiresIPhoneOS -bool true "$app_bundle/Info.plist"
plutil -insert UIDeviceFamily -json "[$family]" "$app_bundle/Info.plist"
if [ "$platform" = "tvos" ]; then
  plutil -insert UIBackgroundModes -json '["audio"]' "$app_bundle/Info.plist"
fi
codesign --force --sign - "$app_bundle"

xcrun simctl boot "$simulator_id" 2>/dev/null || true
xcrun simctl bootstatus "$simulator_id" -b
xcrun simctl install "$simulator_id" "$app_bundle"
if [ -n "${SABELLA_CATALOG_PAGE:-}" ]; then
  export SIMCTL_CHILD_SABELLA_CATALOG_PAGE="$SABELLA_CATALOG_PAGE"
fi
xcrun simctl launch --terminate-running-process "$simulator_id" "$bundle_identifier"
