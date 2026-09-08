#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
release_archive_root=$(mktemp -d "${TMPDIR:-/tmp}/sabella-release-archive.XXXXXX")
trap 'rm -rf "$release_archive_root"' EXIT HUP INT TERM

cd "$repository_root"

scripts/validate-package-contract.py
scripts/validate-kolibri-contract.sh
scripts/create-release-archive.sh 0.2.0 HEAD "$release_archive_root"
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$release_archive_root" && sha256sum -c SHA256SUMS)
else
  (cd "$release_archive_root" && shasum -a 256 -c SHA256SUMS)
fi
swift build --target Sabella
swift test
swift build --product SabellaCatalog
swift build --product SabellaShellExamples
scripts/validate-release-consumer.sh --local
