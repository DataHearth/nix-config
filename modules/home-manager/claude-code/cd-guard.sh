# Claude Code PreToolUse guard against redundant `cd`.
#
# Claude habitually prefixes commands with `cd <project>` even when it is
# already sitting in that directory — a no-op on its own, and pure noise in a
# compound command like `cd <project> && jj st`. This guard catches the
# redundant case (cd into the current directory, or `.`/`./`) and tells Claude
# to drop it. A genuine change (a subdirectory, `..`, anywhere else) is left
# untouched.

input=$(cat)

[ "$(jq -r '.tool_name // empty' <<<"$input")" = "Bash" ] || exit 0

cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$cmd" ] || exit 0

# Where Claude thinks it is.
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$cwd" ] || cwd=$PWD

# Only the leading segment can be a redundant prefix `cd`.
first_seg=$(printf '%s\n' "$cmd" | sed -E 's/&&|\|\||[;|&]/\n/g' | head -n1)
# shellcheck disable=SC2086 # intentional word-splitting into positional args
set -- $first_seg
[ "${1:-}" = "cd" ] && [ "$#" -ge 2 ] || exit 0

target=$2
# strip one layer of surrounding quotes
target=${target#\"}
target=${target%\"}
target=${target#\'}
target=${target%\'}
# expand a leading ~ so `cd ~` is comparable to an absolute cwd. The hook sees
# the raw, unexpanded command string, so the literal tilde is intentional.
# shellcheck disable=SC2088
case "$target" in
  "~") [ -n "${HOME:-}" ] && target=$HOME ;;
  "~/"*) [ -n "${HOME:-}" ] && target=$HOME/${target#"~/"} ;;
esac

norm_cwd=${cwd%/}
redundant=0
case "$target" in
  "." | "./") redundant=1 ;;
  /*) [ "${target%/}" = "$norm_cwd" ] && redundant=1 ;;
esac
[ "$redundant" = 1 ] || exit 0

# Strip the leading `cd <target> <connector>` to show the real command.
rest=$(printf '%s' "$cmd" | sed -E 's/^[[:space:]]*cd[[:space:]]+[^&|;]+([;&]{1,2}|\|\|)[[:space:]]*//')
if [ "$rest" = "$cmd" ]; then
  reason="You are already in $norm_cwd, so this 'cd' is a no-op. Skip it."
else
  reason="You are already in $norm_cwd, so the leading 'cd' is redundant. Drop it and run the rest directly:
  $rest"
fi

jq -n --arg r "$reason" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
