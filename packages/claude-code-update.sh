#!/usr/bin/env nix
#!nix shell --ignore-environment nixpkgs#cacert nixpkgs#coreutils nixpkgs#curl nixpkgs#bash --command bash

# Refresh claude-code-manifest.json to a given version (default: latest).
# Usage: ./claude-code-update.sh [VERSION]
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

BASE_URL="https://downloads.claude.ai/claude-code-releases"

VERSION="${1:-$(curl -fsSL "$BASE_URL/latest")}"

curl -fsSL "$BASE_URL/$VERSION/manifest.json" --output claude-code-manifest.json

echo "Updated claude-code-manifest.json to $VERSION"
