# Claude Code SessionStart + CwdChanged hook: load the current project's
# direnv / nix-direnv devShell into the environment Claude Code runs its Bash
# commands in.
#
# Why this exists: the Claude Desktop "Code" tab — and any non-interactive
# Claude session — launches from the GUI, inheriting none of a project's
# devShell, and runs commands in a non-interactive shell where the usual
# `direnv hook` in the login shell never fires. Project tooling (kubectl, go,
# talosctl, …) is therefore absent from PATH. This hook rebuilds it per
# directory, dynamically.
#
# Mechanism: at SessionStart, Claude Code hands us CLAUDE_ENV_FILE — a file
# whose contents are prepended (joined with `&&`) before every Bash command. We
# wire it, once, to source a per-session snapshot, then (re)generate that
# snapshot from `direnv export bash` for the current directory. CwdChanged
# refreshes the same snapshot when Claude moves between projects, so the
# devShell follows it.
#
# CLAUDE_ENV_FILE is provided ONLY to SessionStart (not CwdChanged), so the
# snapshot path is derived from the session id rather than from CLAUDE_ENV_FILE
# — that way the CwdChanged pass can find and rewrite the same file. Deriving it
# per-session also keeps a concurrent CLI + Desktop session (both supported on
# one project) from clobbering each other's environment.

input=$(cat)

# Per-session snapshot path. Prefer the id from the hook payload; fall back to
# the env var Claude Code exports to every child process.
sid=$(jq -r '.session_id // empty' <<<"$input")
[ -n "$sid" ] || sid=${CLAUDE_CODE_SESSION_ID:-default}
snapdir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-code-direnv"
snapshot="$snapdir/$sid.env"
mkdir -p "$snapdir"

# Run direnv against the directory Claude is actually in (the payload's cwd is
# authoritative; the hook's own cwd is only a fallback).
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$cwd" ] || cwd=$PWD
cd "$cwd" 2>/dev/null || true

# (Re)generate the snapshot for this directory. Best-effort: no .envrc, a
# blocked .envrc (needs a one-time `direnv allow`), or any direnv error just
# yields an inert snapshot, which sources cleanly and loads nothing. The
# trailing `true` also guarantees `. snapshot` returns 0, so the `&&`-joined
# command still runs (a bare trailing `;` from direnv would otherwise make
# `; &&` a syntax error once inlined).
{
  direnv export bash 2>/dev/null || true
  echo "true"
} >"$snapshot"

# Only SessionStart is handed CLAUDE_ENV_FILE. Wire it — once — to source the
# snapshot before each Bash command. Appended, never overwritten: other hooks
# share this file.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  grep -qF "$snapshot" "$CLAUDE_ENV_FILE" 2>/dev/null \
    || printf '. %q\n' "$snapshot" >>"$CLAUDE_ENV_FILE"
fi

exit 0
