#!/usr/bin/env nix
#!nix shell --ignore-environment nixpkgs#cacert nixpkgs#coreutils nixpkgs#curl nixpkgs#gnused nixpkgs#gawk nixpkgs#nix nixpkgs#bash --command bash

# Update the manually-packaged apps in this directory: refresh version(s) and
# hash(es) in place so a plain `nh os build` picks up the new release.
#
# Usage: ./update.sh <package|all> [version]
#
#   all                        update every package below to its latest
#   claude-code    [version]   refresh claude-code-manifest.json   (default: latest)
#   claude-desktop [version]   bump version + both .deb hashes      (default: latest in apt index)
#   f5vpn                      re-prefetch the latest linux_f5vpn.x86_64.deb
#   f5epi                      re-prefetch the latest linux_f5epi.x86_64.rpm
#
# f5vpn/f5epi track a fixed "latest" URL on Airbus's portal, so they take no
# version argument.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Prefetch a URL into the store and echo its SRI hash (sha256-...).
prefetch_sri() {
  nix store prefetch-file --json "$1" \
    | sed -n 's/.*"hash":"\([^"]*\)".*/\1/p'
}

# Read the SHA256 hex from the apt Packages stanza (on stdin) whose Version is $1.
sha256_for_version() {
  awk -v ver="$1" 'BEGIN { RS = ""; FS = "\n" } {
    v = ""; s = "";
    for (i = 1; i <= NF; i++) {
      if ($i ~ /^Version: /) { v = substr($i, 10) }
      if ($i ~ /^SHA256: /)  { s = substr($i, 9)  }
    }
    if (v == ver) { print s; exit }
  }'
}

update_claude_code() {
  local base="https://downloads.claude.ai/claude-code-releases"
  local version="${1:-$(curl -fsSL "$base/latest")}"
  curl -fsSL "$base/$version/manifest.json" --output claude-code-manifest.json
  echo "claude-code: manifest updated to $version"
}

update_claude_desktop() {
  local dist="https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main"
  local version="$1"
  if [ -z "$version" ]; then
    version=$(curl -fsSL "$dist/binary-amd64/Packages" \
      | awk '/^Version: /{print $2}' | sort -V | tail -1)
  fi
  # Both arch hashes (hex) come straight from the apt Packages index.
  local amd64 arm64
  amd64=$(curl -fsSL "$dist/binary-amd64/Packages" | sha256_for_version "$version")
  arm64=$(curl -fsSL "$dist/binary-arm64/Packages" | sha256_for_version "$version")
  if [ -z "$amd64" ] || [ -z "$arm64" ]; then
    echo "claude-desktop: version $version not found in apt index" >&2
    exit 1
  fi
  sed -i \
    -e "s/version = \"[^\"]*\";/version = \"$version\";/" \
    -e "/_amd64.deb/{n;s/sha256 = \"[^\"]*\"/sha256 = \"$amd64\"/;}" \
    -e "/_arm64.deb/{n;s/sha256 = \"[^\"]*\"/sha256 = \"$arm64\"/;}" \
    claude-desktop.nix
  echo "claude-desktop: bumped to $version"
}

update_f5vpn() {
  local sri
  sri=$(prefetch_sri "https://axess.airbus.com/public/download/linux_f5vpn.x86_64.deb")
  sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$sri\"|" f5vpn.nix
  echo "f5vpn: hash updated to $sri"
}

update_f5epi() {
  local sri
  sri=$(prefetch_sri "https://axess.airbus.com/public/download/linux_f5epi.x86_64.rpm")
  sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$sri\"|" f5epi.nix
  echo "f5epi: hash updated to $sri"
}

case "${1:-}" in
  all)
    update_claude_code
    update_claude_desktop ""
    update_f5vpn
    update_f5epi
    ;;
  claude-code)    update_claude_code    "${2:-}" ;;
  claude-desktop) update_claude_desktop "${2:-}" ;;
  f5vpn)          update_f5vpn ;;
  f5epi)          update_f5epi ;;
  "" | -h | --help | help)
    sed -n '4,16p' "$0"
    ;;
  *)
    echo "unknown package: ${1:-}" >&2
    echo "  known: all, claude-code, claude-desktop, f5vpn, f5epi" >&2
    exit 1
    ;;
esac
