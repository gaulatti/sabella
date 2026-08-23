#!/bin/sh
set -eu

mode="${1:---local}"
repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
consumer_root=$(mktemp -d "${TMPDIR:-/tmp}/sabella-release-consumer.XXXXXX")
trap 'rm -rf "$consumer_root"' EXIT HUP INT TERM

case "$mode" in
  --local)
    dependency=".package(name: \"Sabella\", path: \"$repository_root\")"
    ;;
  --remote)
    release_version="${SABELLA_RELEASE_VERSION:-0.1.0}"
    if ! printf '%s\n' "$release_version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      echo "SABELLA_RELEASE_VERSION must be a semantic version." >&2
      exit 64
    fi
    dependency=".package(url: \"https://github.com/gaulatti/sabella.git\", .upToNextMinor(from: \"$release_version\"))"
    ;;
  *)
    echo "usage: $0 --local|--remote" >&2
    exit 64
    ;;
esac

mkdir -p "$consumer_root/Sources/ReleaseConsumer"
cp "$repository_root/Tests/ReleaseConsumer/main.swift" "$consumer_root/Sources/ReleaseConsumer/main.swift"

{
  printf '%s\n' '// swift-tools-version: 6.0'
  printf '%s\n' 'import PackageDescription'
  printf '%s\n' ''
  printf '%s\n' 'let package = Package('
  printf '%s\n' '    name: "SabellaReleaseConsumer",'
  printf '%s\n' '    platforms: [.macOS(.v14)],'
  printf '%s\n' '    dependencies: ['
  printf '        %s,\n' "$dependency"
  printf '%s\n' '    ],'
  printf '%s\n' '    targets: ['
  printf '%s\n' '        .executableTarget('
  printf '%s\n' '            name: "ReleaseConsumer",'
  printf '%s\n' '            dependencies: [.product(name: "Sabella", package: "Sabella")]'
  printf '%s\n' '        ),'
  printf '%s\n' '    ]'
  printf '%s\n' ')'
} > "$consumer_root/Package.swift"

swift build --package-path "$consumer_root" --product ReleaseConsumer
