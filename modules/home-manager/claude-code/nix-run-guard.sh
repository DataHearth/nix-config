# Claude Code PreToolUse guard for NixOS.
#
# This machine installs software declaratively — language runtimes and dev
# tools like python3/node/cargo are deliberately NOT on the global PATH. When
# Claude reaches for one bare, the command would just fail with "command not
# found". This guard catches that before the command runs and tells Claude the
# Nix-native way to run it instead: the project's own devshell, or an ephemeral
# `nix run` / `nix shell`.
#
# It only ever intervenes when BOTH hold:
#   1. the leading word of a command segment is a known dev tool, AND
#   2. that tool is not resolvable on the current PATH.
# So anything actually available — installed system-wide, via home-manager, or
# through an already-active devshell — is never touched. `command -v` is the
# real gate; the tool list below just keeps the guard from second-guessing
# unrelated commands (typos, project scripts, …).

input=$(cat)

[ "$(jq -r '.tool_name // empty' <<<"$input")" = "Bash" ] || exit 0

cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$cmd" ] || exit 0

guarded=" python python3 pip pip3 pipx uv poetry node nodejs npm npx yarn pnpm bun deno ts-node tsx ruby gem bundle bundler cargo rustc go php composer "

# Best-effort tool -> nixpkgs attribute. Just a hint; Claude can refine it.
attr_for() {
  case "$1" in
    node | npm | npx) echo nodejs ;;
    pip | pip3 | python) echo python3 ;;
    gem | bundle | bundler) echo ruby ;;
    rustc) echo cargo ;;
    *) echo "$1" ;;
  esac
}

# The real Bash environment Claude runs commands in has the per-session direnv
# snapshot sourced ahead of every command (see ./load-direnv.sh), so a project
# devShell's tools (go, node, cargo, …) sit on that PATH. This guard, though,
# runs as a bare PreToolUse subprocess that never gets the CLAUDE_ENV_FILE
# prepend, so a naive `command -v` here checks a devShell-less PATH and would
# wrongly flag every devShell-only tool as absent. Derive the snapshot path from
# session_id exactly as load-direnv.sh does.
sid=$(jq -r '.session_id // empty' <<<"$input")
[ -n "$sid" ] || sid=${CLAUDE_CODE_SESSION_ID:-default}
snapshot="${XDG_STATE_HOME:-$HOME/.local/state}/claude-code-direnv/$sid.env"

# Resolve a tool against the env the command will actually run in. Subshell so
# sourcing the snapshot (which sets an absolute PATH) can't clobber the PATH
# this guard needs for its own jq/sed/coreutils further down; nounset off so a
# stray unset-var reference in the snapshot can't abort the check. Missing or
# inert snapshot -> nothing sourced -> falls back to today's behavior.
tool_available() {
  (
    set +o nounset
    # shellcheck disable=SC1090
    [ -f "$snapshot" ] && . "$snapshot"
    command -v "$1" >/dev/null 2>&1
  )
}

# Strip quoted spans and heredoc bodies before looking for command boundaries.
# A `;`, `|` or `&&` inside an argument is not a boundary, and splitting on it
# anyway promotes a tool name that is merely being *mentioned* into a segment
# head: `git commit -m "docs; npm install"` and a heredoc whose body line reads
# `node index.js` would both be denied. It is also what keeps a command the
# container or the remote host runs -- `docker exec app sh -c "cd /app && npm
# ci"`, `kubectl exec pod -- sh -c "…"`, `ssh host "cd /srv && python3 x.py"`
# -- out of the guard: none of those resolve against this machine's PATH.
# Worth the care because the guard otherwise contradicts itself; the compound
# form it recommends below, `nix develop -c bash -c '<cmd>'`, splits on the
# quoted `&&` and gets denied in turn, so a deny can suggest a command that
# denies again.
#
# The trade is under-firing: a genuinely local `bash -c "npm ci"` now reads as
# a bare `bash` and passes. That direction is the safe one -- the command just
# fails with "command not found", which is the outcome this guard improves on,
# not one it has to prevent.
cleaned=$(printf '%s\n' "$cmd" | awk '
  BEGIN { sq = sprintf("%c", 39); dq = sprintf("%c", 34); q = ""; hd = ""; strip = 0 }
  {
    line = $0
    if (hd != "") {
      t = line
      if (strip) sub(/^\t+/, "", t)
      if (t == hd) hd = ""
      next
    }
    out = ""
    n = length(line)
    i = 1
    while (i <= n) {
      c = substr(line, i, 1)
      if (q != "") {
        if (q == dq && c == "\\") { i += 2; continue }
        if (c == q) q = ""
        i++
        continue
      }
      if (c == "\\") { i += 2; continue }
      if (c == sq || c == dq) { q = c; i++; continue }
      if (c == "<" && substr(line, i + 1, 1) == "<") {
        j = i + 2
        if (substr(line, j, 1) == "<") { i = j + 1; continue }
        strip = 0
        if (substr(line, j, 1) == "-") { strip = 1; j++ }
        while (substr(line, j, 1) == " ") j++
        w = ""
        while (j <= n) {
          ch = substr(line, j, 1)
          if (ch ~ /[ \t;|&<>()]/) break
          if (ch != sq && ch != dq && ch != "\\") w = w ch
          j++
        }
        hd = w
        i = j
        continue
      }
      out = out c
      i++
    }
    print out
  }
')

# Inspect each pipeline/list segment's leading word so `cd x && python3 y` is
# caught, not just a command that starts with the tool.
missing=""
while IFS= read -r seg; do
  # shellcheck disable=SC2086 # intentional word-splitting into positional args
  set -- $seg
  # drop leading VAR=val assignments and command wrappers
  while [ "$#" -gt 0 ]; do
    case "$1" in
      *=*) shift ;;
      sudo | command | exec | time | nice | nohup | env | builtin | then | do | else) shift ;;
      *) break ;;
    esac
  done
  [ "$#" -gt 0 ] || continue
  word=$1
  case "$word" in */*) continue ;; esac # skip explicit paths (./x, /usr/bin/x)
  case "$guarded" in *" $word "*) ;; *) continue ;; esac
  if ! tool_available "$word"; then
    case " $missing " in *" $word "*) ;; *) missing="$missing $word" ;; esac
  fi
done < <(printf '%s\n' "$cleaned" | sed -E 's/&&|\|\||[;|&]/\n/g')

[ -n "$missing" ] || exit 0
missing="${missing# }"

# Is a devshell in scope? Walk up for flake.nix / shell.nix / .envrc. The
# common setup here is a flake devShell wired up through direnv (use flake), so
# an unresolved tool usually just means the devShell isn't active yet.
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$cwd" ] || cwd=$PWD
has_flake=0
has_shell=0
has_direnv=0
dir=$cwd
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
  [ -e "$dir/.envrc" ] && has_direnv=1
  if [ -e "$dir/flake.nix" ]; then
    has_flake=1
    has_shell=1
    break
  fi
  if [ -e "$dir/shell.nix" ] || [ -e "$dir/.envrc" ]; then
    has_shell=1
    break
  fi
  dir=$(dirname "$dir")
done

hints=""
for t in $missing; do
  hints="$hints  - $t -> nix run nixpkgs#$(attr_for "$t") -- <args>
"
done

# How to run the original command inside the devShell. `nix develop -c` only
# takes one simple command, so wrap compound commands in bash -c. Tested on the
# cleaned text: an operator inside a quoted argument does not make the command
# compound, and suggesting the bash -c wrapper for one is just noise.
case "$cleaned" in
  *"&&"* | *"||"* | *";"* | *"|"*) devrun="nix develop -c bash -c '<your full command>'" ;;
  *) devrun="nix develop -c $cmd" ;;
esac

if [ "$has_flake" = 1 ]; then
  if [ "$has_direnv" = 1 ]; then
    primary="This project has a flake devShell wired up through direnv, so these tools most likely live there and the devShell just is not active. Reload it ('direnv allow' on first use, or 'direnv reload' to refresh) so the tools land on PATH, or run this command inside the devShell directly:
  $devrun"
  else
    primary="This project has a flake devShell — if it bundles these tools, run the command inside it:
  $devrun"
  fi
elif [ "$has_shell" = 1 ]; then
  primary="This project declares a devshell (shell.nix/.envrc). If it bundles these tools, activate it first (direnv allow, or enter the nix-shell)."
else
  primary="There is no devshell here, so use an ephemeral one."
fi

reason="Not on PATH: $missing
This machine is NixOS; binaries are not installed ad-hoc, so do not run them bare.

$primary

Otherwise run them ephemerally via Nix:
$hints  (for several commands from one package, use: nix shell nixpkgs#<pkg> -c <cmd>)

Re-issue the command using one of these forms."

jq -n --arg r "$reason" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
