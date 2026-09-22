#!/usr/bin/env bash
# Table test for nix-run-guard.sh.
#
# The guard's verdict depends on what resolves on PATH, so the test builds its
# own: a fake session snapshot pointing PATH at a directory holding a single
# stub (python3). Everything else -- npm, node, cargo, go -- is absent by
# construction, no matter what this machine has installed. That also exercises
# the snapshot lookup itself, which is the only reason the guard does not flag
# every devShell-only tool as missing.
set -o nounset -o pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
guard=$here/nix-run-guard.sh

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/state/claude-code-direnv" "$tmp/cwd"
printf '#!/bin/sh\n' >"$tmp/bin/python3"
chmod +x "$tmp/bin/python3"
printf 'export PATH=%s\n' "$tmp/bin" >"$tmp/state/claude-code-direnv/test-sid.env"

failures=0

verdict() {
  local out
  out=$(jq -n --arg c "$1" --arg d "$tmp/cwd" \
    '{tool_name:"Bash",session_id:"test-sid",cwd:$d,tool_input:{command:$c}}' |
    XDG_STATE_HOME=$tmp/state bash "$guard")
  if [ -z "$out" ]; then
    echo "ALLOW"
  else
    jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$out" | head -1
  fi
}

check() { # expected(ALLOW|DENY) description command
  local got status
  got=$(verdict "$3")
  case "$got" in
    ALLOW) status=ALLOW ;;
    *) status=DENY ;;
  esac
  if [ "$status" = "$1" ]; then
    printf 'ok    %-44s %s\n' "$2" "$status"
  else
    printf 'FAIL  %-44s want %s, got %s\n' "$2" "$1" "$got"
    failures=$((failures + 1))
  fi
}

# A tool that really would run bare on this PATH, in every shape the segment
# scanner is meant to see through.
check DENY 'bare invocation' 'npm ci'
check DENY 'compound, tool in second segment' 'cd /x && npm ci'
check DENY 'wrapper prefix' 'sudo npm ci'
check DENY 'assignment prefix' 'NODE_ENV=test npm test'
# shellcheck disable=SC2016 # the command under test is data, not shell to expand
check DENY 'loop body' 'for f in *.js; do node "$f"; done'
check DENY 'pipeline target' 'cat x.json | node process.js'
check DENY 'subshell' '(cd web && npm ci)'
check DENY 'second line' $'cd /x\nnpm ci'
check DENY 'after a heredoc terminator' $'cat <<EOF > f\nnpm ci\nEOF\nnpm test'
check DENY 'line continuation' $'cd /x && \\\n  npm ci'
check DENY 'a different absent tool' 'cargo build --release'

# Resolvable through the session snapshot: never touched.
check ALLOW 'tool present on the session PATH' "python3 -c 'print(1)'"

# The tool name is data, not a command.
check ALLOW 'quoted separator in a message' 'git commit -m "docs; npm install notes"'
check ALLOW 'quoted separator, single quotes' "git commit -m 'a; npm i'"
check ALLOW 'nested quotes' 'git commit -m "say '"'"'npm ci'"'"' here"'
check ALLOW 'escaped quotes' 'echo "he said \"npm ci; go build\""'
check ALLOW 'alternation in a pattern' 'rg "python3|node" .'
check ALLOW 'awk program' "awk '{ print \$1; node = 2 }' f"
check ALLOW 'sed program' "sed -i 's/npm ci/go build/' README.md"
check ALLOW 'heredoc body' $'cat <<EOF\nnode index.js\nEOF'
check ALLOW 'heredoc, quoted delimiter' $'cat <<\'EOF\'\ngo build ./...\nEOF'
check ALLOW 'heredoc, tab-indented (<<-)' $'cat <<-EOF\n\tnpm ci\n\tEOF'
check ALLOW 'here-string' 'jq . <<< "{\"cmd\":\"npm ci\"}"'

# The command runs somewhere that is not this PATH.
check ALLOW 'nix run' 'nix run nixpkgs#nodejs -- --version'
check ALLOW 'nix develop' 'nix develop -c npm ci'
check ALLOW 'nix develop, compound inner command' 'nix develop -c bash -c "cd web && npm ci"'
check ALLOW 'docker exec' 'docker exec app npm run build'
check ALLOW 'docker exec, compound inner command' 'docker exec app sh -c "cd /app && npm ci"'
check ALLOW 'kubectl exec' 'kubectl exec pod-1 -- sh -c "cd /app && npm ci"'
check ALLOW 'ssh' 'ssh host "cd /srv && cargo build"'
check ALLOW 'explicit path' './node_modules/.bin/tsc'

# Degenerate input must fall through rather than hang or crash.
check ALLOW 'unterminated quote' 'echo "unclosed; npm ci'
check ALLOW 'empty command' ''

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures"
  exit 1
fi
printf '\nall tests passed\n'
