#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
pin="$repository_root/Tests/Fixtures/Kolibri/PIN.json"
bundle="$repository_root/Tests/Fixtures/Kolibri/0.1.0"
fixture="$bundle/fixtures/static-component.json"
expected_manifest_sha="aec1a74fb557ab0a5d254b5ac8d98306e552dc88cdb6ebeeb6f98d1460cfe134"

actual_manifest_sha=$(shasum -a 256 "$bundle/manifest.json" | awk '{print $1}')
if [ "$actual_manifest_sha" != "$expected_manifest_sha" ]; then
  echo "Kolibri bundle manifest drifted: $actual_manifest_sha != $expected_manifest_sha" >&2
  exit 1
fi

/usr/bin/python3 - "$pin" "$expected_manifest_sha" <<'PY'
import json
import sys

pin_path, expected_manifest_sha = sys.argv[1:]
with open(pin_path, encoding="utf-8") as file:
    pin = json.load(file)

expected = {
    "bundleManifestSHA256": expected_manifest_sha,
    "releasePath": "contract/releases/0.1.0",
    "releaseVersion": "0.1.0",
    "repository": "gaulatti/kolibri",
    "repositoryCommit": "f14a631a001f867e208be6053ac07df32fda4dca",
    "repositoryVisibility": "private",
    "selectedFixture": "fixtures/static-component.json",
}
if pin != expected:
    raise SystemExit(f"Kolibri pin drifted: {pin!r} != {expected!r}")
PY

node "$bundle/bin/validate.mjs" "$bundle" "$fixture"
