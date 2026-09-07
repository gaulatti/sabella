#!/bin/sh
set -eu

version=${1:?"usage: $0 <version> [git-ref] [output-directory]"}
git_ref=${2:-HEAD}
output_directory=${3:-.}

if ! printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "version must be a semantic version." >&2
  exit 64
fi

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
archive_name="Sabella-$version.tar.gz"
archive_path="$output_directory/$archive_name"
checksum_path="$output_directory/SHA256SUMS"

mkdir -p "$output_directory"
git -C "$repository_root" cat-file -e "$git_ref^{commit}"
git -C "$repository_root" archive \
  --format=tar \
  --prefix="Sabella-$version/" \
  "$git_ref" | gzip -n > "$archive_path"

if command -v sha256sum >/dev/null 2>&1; then
  (cd "$output_directory" && sha256sum "$archive_name" > SHA256SUMS)
else
  (cd "$output_directory" && shasum -a 256 "$archive_name" > SHA256SUMS)
fi

printf '%s\n' "$archive_path" "$checksum_path"
