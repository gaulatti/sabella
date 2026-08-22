#!/bin/sh
set -eu

platform="${1:-macos}"
repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

case "$platform" in
  macos)
    cd "$repository_root"
    swift run SabellaShellExamples ${SHELL_EXAMPLE_ARGUMENTS:-}
    exit 0
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

derived_data="${DERIVED_DATA_PATH:-$repository_root/.build/shell-example-$platform}"
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

cd "$repository_root"
xcodebuild \
  -scheme SabellaShellExamples \
  -destination "platform=$sdk_platform,id=$simulator_id" \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  build

executable="$derived_data/Build/Products/Debug-$sdk/SabellaShellExamples"
app_bundle="$derived_data/SabellaShellExamples.app"
bundle_identifier="com.gaulatti.sabella.shell-examples.$platform"

test -x "$executable"
mkdir -p "$app_bundle"
cp "$executable" "$app_bundle/SabellaShellExamples"

plutil -create xml1 "$app_bundle/Info.plist"
plutil -insert CFBundleDisplayName -string "Sabella Shell Examples" "$app_bundle/Info.plist"
plutil -insert CFBundleExecutable -string SabellaShellExamples "$app_bundle/Info.plist"
plutil -insert CFBundleIdentifier -string "$bundle_identifier" "$app_bundle/Info.plist"
plutil -insert CFBundleName -string SabellaShellExamples "$app_bundle/Info.plist"
plutil -insert CFBundlePackageType -string APPL "$app_bundle/Info.plist"
plutil -insert CFBundleShortVersionString -string 1.0 "$app_bundle/Info.plist"
plutil -insert CFBundleVersion -string 1 "$app_bundle/Info.plist"
plutil -insert LSRequiresIPhoneOS -bool true "$app_bundle/Info.plist"
plutil -insert UIDeviceFamily -json "[$family]" "$app_bundle/Info.plist"
codesign --force --sign - "$app_bundle"

xcrun simctl boot "$simulator_id" 2>/dev/null || true
xcrun simctl bootstatus "$simulator_id" -b
xcrun simctl install "$simulator_id" "$app_bundle"

if [ "${SHELL_EXAMPLE_MODE:-tabs}" = "admin" ]; then
  xcrun simctl launch --terminate-running-process "$simulator_id" "$bundle_identifier" --admin
else
  xcrun simctl launch --terminate-running-process "$simulator_id" "$bundle_identifier"
fi
