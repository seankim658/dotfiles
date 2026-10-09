#!/bin/bash

set -euo pipefail

## Apply a patch to the current git repo and open it for review in Diffview
##
## Usage: review-patch.sh <patch-file>
##
## The patch is applied without staging, so the Diffview file panel lists every
## changed file under "Changes". Stage what you approve and restore the rest.
## Refuses to run when the repo has uncommitted changes, so the review only
## shows what the patch changed.

usage() {
  echo "Usage: $(basename "$0") <patch-file>" >&2
  exit 1
}

fail() {
  echo "$1" >&2
  exit 1
}

# Print the absolute path of a file, since the script changes directory
absolute_path() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

require_clean_repo() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    fail "The repo has uncommitted changes. Commit or stash them first."
  fi
}

if [ "$#" -ne 1 ]; then
  usage
fi

if [ ! -f "$1" ]; then
  fail "Patch file not found: $1"
fi
patch_file="$(absolute_path "$1")"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || fail "Not inside a git repo: $(pwd)"
cd "$repo_root"

require_clean_repo

if ! git apply --check "$patch_file"; then
  fail "The patch does not apply cleanly: $patch_file"
fi

git apply "$patch_file"
echo "Applied $(basename "$patch_file")"

exec nvim +DiffviewOpen
