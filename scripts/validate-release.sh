#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

cd "$repository_root"

scripts/validate-package-contract.py
scripts/validate-kolibri-contract.sh
swift build --target Sabella
swift test
swift build --product SabellaCatalog
swift build --product SabellaShellExamples
scripts/validate-release-consumer.sh --local
