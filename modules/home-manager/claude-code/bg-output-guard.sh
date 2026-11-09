# Claude Code PreToolUse guard: a `run_in_background` Bash call must stream its
# output to stdout/stderr as it runs. The harness captures those streams and
# the user watches them live to tell a working task from a stalled one. The
# rule lives in context.md, but agents ignore prose, so this enforces it.
#
# Denied:
#   - redirecting fd 1/2 anywhere but onto each other (`> f`, `&> f`,
#     `2>/dev/null`, `| tee f >/dev/null`, `>&-`), and `nohup`
#   - `| tail` / `| head`: nothing shows until the command exits
#   - detaching (`setsid`, `disown`, a trailing `&`): the harness loses the task
# Exempt, because they silence a probe rather than the task:
#   - anything inside `$(…)` but a file redirect (captured, never shown anyway)
#   - `/dev/null` in an `until`/`while`/`if` condition, or after `command -v`
#   - a bare `> file` that only truncates it
#
# Quoted text is scanned like the rest: it is often a nested script
# (`sh -c '…'`, `ssh host '…'`, `kubectl exec … -- sh -c '…'`). The price is a
# false deny on a quoted literal like `jq '.a > 1'`, which the agent rewrites.
#
# Run ./bg-output-guard-test.sh after any change.

input=$(cat)

[ "$(jq -r '.tool_input.run_in_background // false' <<<"$input")" = "true" ] || exit 0

cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$cmd" ] || exit 0

nl=$'\n'
devnull='[0-9]*&?>>?\|?[[:space:]]*/dev/null'
redirect='(^|[^-=<>&0-9])[0-9]*&?>>?\|?[[:space:]]*([^&[:space:]]|&[^12])'

# Replace the first occurrence of $2 in $1 with $3.
replace_first() {
  printf '%s' "${1%%"$2"*}$3${1#*"$2"}"
}

strip_devnull() {
  local s=$1
  while [[ $s =~ $devnull ]]; do
    s=$(replace_first "$s" "${BASH_REMATCH[0]}" "")
  done
  printf '%s' "$s"
}

s=$cmd

# Innermost first, so nested substitutions collapse one layer per pass.
subst='\$\(([^()]*)\)'
while [[ $s =~ $subst ]]; do
  whole=${BASH_REMATCH[0]}
  inner=$(strip_devnull "${BASH_REMATCH[1]}")
  if [[ $inner =~ $redirect ]]; then repl=' >SUBST '; else repl='SUBST'; fi
  s=$(replace_first "$s" "$whole" "$repl")
done

# The condition stops at the first unquoted `;`/newline before `do`/`then`.
cond="(^|[^[:alnum:]_])(until|while|if|elif)[[:space:]]+(([^;${nl}'\"]|'[^']*'|\"[^\"]*\")*)([;${nl}][[:space:]]*(do|then)([[:space:]]|$))"
while [[ $s =~ $cond ]]; do
  whole=${BASH_REMATCH[0]}
  s=$(replace_first "$s" "$whole" "${BASH_REMATCH[1]}COND $(strip_devnull "${BASH_REMATCH[3]}")${BASH_REMATCH[5]}")
done

probe="(^|[^[:alnum:]_])(command[[:space:]]+-v|type|which|hash)[[:space:]]([^;&|${nl}]|&>|>&)*"
while [[ $s =~ $probe ]]; do
  whole=${BASH_REMATCH[0]}
  s=$(replace_first "$s" "$whole" "${BASH_REMATCH[1]}PROBE $(strip_devnull "${whole#*"${BASH_REMATCH[2]}"}")")
done

truncate="(^|[;|({${nl}]|&&|&[[:space:]])[[:space:]]*:?[[:space:]]*>[[:space:]]*[^;&|<>[:space:]]+[[:space:]]*([;&|${nl}]|$)"
while [[ $s =~ $truncate ]]; do
  s=$(replace_first "$s" "${BASH_REMATCH[0]}" "${BASH_REMATCH[1]}TRUNC${BASH_REMATCH[2]}")
done

# `tail -f` streams, so mark it before looking for a buffering `| tail`.
follow="(^|[^[:alnum:]_])tail(([[:space:]]+[^;&|${nl}]*)?[[:space:]](-[[:alnum:]]*[fF][[:alnum:]]*|--follow))"
while [[ $s =~ $follow ]]; do
  s=$(replace_first "$s" "${BASH_REMATCH[0]}" "${BASH_REMATCH[1]}TAILF${BASH_REMATCH[2]}")
done

buffered="\|&?[[:space:]]*(tail|head)([[:space:]]|$|[;&|)])"
detach="(^|[[:space:];&|(\"'])(nohup|setsid|disown)([[:space:]]|$)"
trailing_bg="(^|[^&])&[[:space:]]*$"

reason=
if [[ $s =~ $redirect ]]; then
  reason="Keep the output on stdout/stderr: a redirect to a file or /dev/null hides it. To also keep a file, use 'cmd 2>&1 | tee <file>' with nothing silencing tee's stdout. Silencing a probe is fine inside \$(…), an until/while/if condition, or after 'command -v'."
elif [[ $s =~ $buffered ]]; then
  reason="Drop the '| ${BASH_REMATCH[1]}': it holds everything back until the command exits, so a stall looks the same as a quiet build. Read the end of the output once the task completes."
elif [[ $cmd =~ $detach ]]; then
  reason="Drop the ${BASH_REMATCH[2]}: run_in_background already backgrounds the command and tracks it to completion; detaching it from the harness hides it."
elif [[ $cmd =~ $trailing_bg ]]; then
  reason="Drop the trailing '&': run_in_background already backgrounds the command, and an extra '&' lets the shell exit while the job keeps running untracked."
fi

[ -n "$reason" ] || exit 0
reason="Denied for a run_in_background command. The harness streams its stdout/stderr live to the user's TUI, who watches it to tell a working task from a stalled one. $reason"
jq -n --arg r "$reason" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
