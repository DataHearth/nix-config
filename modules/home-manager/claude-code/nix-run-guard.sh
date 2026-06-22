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
  if ! command -v "$word" >/dev/null; then
    case " $missing " in *" $word "*) ;; *) missing="$missing $word" ;; esac
  fi
done < <(printf '%s\n' "$cmd" | sed -E 's/&&|\|\||[;|&]/\n/g')

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
# takes one simple command, so wrap compound commands in bash -c.
case "$cmd" in
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
