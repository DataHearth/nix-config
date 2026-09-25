# jj workspaces in place of `git worktree`, for Claude Code.
#
#   claude-jj-workspace add <name> [base]   create; prints the path (base: @)
#   claude-jj-workspace remove <name|path>  snapshot, forget, delete
#
# Without arguments it is the WorktreeCreate + WorktreeRemove hook, reading
# the event from stdin, so `claude --worktree`, subagents with
# `isolation: "worktree"` and background sessions get the same workspaces as
# manual `add`.
#
# Defining WorktreeCreate replaces Claude Code's git logic in every repo, so a
# repo without jj gets no isolation at all: creation fails loudly rather than
# falling back to git.
#
# Workspaces live outside the repo. A secondary jj workspace has no .git, so
# one nested in the colocated tree resolves to the main checkout under git and
# Claude Code refuses it.
#
# Only the last stdout line of WorktreeCreate is read, as the workspace path;
# everything else goes to stderr.
#
# WorktreeRemove never fires for a subagent's workspace (Claude Code 2.1.282).
# Claude Code removes a hook-based worktree only when it has a way to tell
# whether it changed: `git rev-parse HEAD`, which fails without .git, or a
# file snapshot whose function (`jut`) is still a stub that returns nothing.
# So every isolated subagent leaves its workspace behind until someone runs
# `remove`. A SubagentStop hook calling `remove` would clean up, but it would
# break resuming a finished agent through SendMessage. Check again after
# Claude Code updates: once the snapshot is implemented, the leftovers stop.

root="$HOME/.claude/workspaces"

# Ignored entries are copied so a workspace keeps the configuration of the tree
# it came from (.env, kubeconfigs, credential dirs, an ignored flake.nix or
# CLAUDE.md). Entries over this size are dependency trees, build output and
# scratch data: they are listed in .jj/skipped-ignored instead, for the agent
# to copy on demand. Besides the copy time, a workspace has no .git, so
# `use flake` loads it as a path: flake and copies the whole tree, ignored
# files included, into the store.
#
# The size is apparent, not on-disk: a sparse file costs nothing to cp but Nix
# reads every byte of it.
max_copy_bytes=$((10 * 1024 * 1024))

repo_dir() {
  local git_dir main
  git_dir=$(jj git root)
  main=${git_dir%/.git}
  main=${main%/.jj/repo/store/git}
  printf '%s/%s\n' "$root" "$(basename "$main")"
}

create() {
  local name=$1 rev=$2 src git_dir dir skipped path size
  local -a copy=()
  if ! src=$(jj workspace root); then
    echo "claude-jj-workspace: $PWD is not a jj repo; run 'jj git init --colocate' to use worktree isolation here" >&2
    exit 1
  fi
  git_dir=$(jj git root)
  dir="$(repo_dir)/$name"
  mkdir -p "$(dirname "$dir")"

  jj workspace add --name "$name" -r "$rev" "$dir" >&2

  skipped="$dir/.jj/skipped-ignored"
  {
    echo "# Ignored entries of $src not copied into this workspace (bytes, path)."
    echo "# Copy what the task needs: cp -a --parents -t . -- <path>, run from $src"
  } >"$skipped"

  # git only lists the ignored paths; --git-dir keeps that working when the
  # source is itself a secondary, git-less workspace. --directory reports an
  # ignored directory as one entry, so it is measured and copied whole. The
  # source's .jj is reported because jj ignores its contents; the workspace
  # already has its own, which a copy would overwrite.
  while IFS= read -r -d '' path; do
    [[ $path == .jj/* ]] && continue
    if size=$(du -sb -- "$src/$path") && ((${size%%$'\t'*} <= max_copy_bytes)); then
      copy+=("$path")
    else
      printf '%s\t%s\n' "${size%%$'\t'*}" "$path" >>"$skipped"
    fi
  done < <(git --git-dir="$git_dir" --work-tree="$src" -C "$src" \
    ls-files -z --others --ignored --exclude-standard --directory)

  if ((${#copy[@]})); then
    (cd "$src" && cp -a --parents -t "$dir" -- "${copy[@]}")
  fi

  # direnv keys its allow-list on the .envrc path, which is new here.
  if [ -f "$dir/.envrc" ]; then
    direnv allow "$dir" >&2
  fi

  printf '%s\n' "$dir"
}

remove() {
  local dir=$1
  case "$dir" in
    "$root"/*) ;;
    *)
      echo "claude-jj-workspace: refusing to remove $dir, which is outside $root" >&2
      exit 1
      ;;
  esac

  # Snapshot first so unsnapshotted edits land in the workspace's commit,
  # which outlives `forget`; deleting the directory then loses nothing.
  if [ -d "$dir/.jj" ]; then
    jj -R "$dir" util snapshot >&2
    jj -R "$dir" workspace forget >&2
  fi
  rm -rf -- "$dir"
}

hook() {
  local input cwd
  input=$(cat)
  case "$(jq -r '.hook_event_name' <<<"$input")" in
    WorktreeCreate)
      cwd=$(jq -r '.cwd // empty' <<<"$input")
      cd "${cwd:-$PWD}" || exit 1
      create "$(jq -r '.name' <<<"$input")" @
      ;;
    WorktreeRemove)
      remove "$(jq -r '.worktree_path' <<<"$input")"
      ;;
  esac
}

usage() {
  echo "usage: claude-jj-workspace add <name> [base] | remove <name|path>" >&2
  exit 2
}

case "${1:-}" in
  "") hook ;;
  add)
    [ $# -ge 2 ] || usage
    create "$2" "${3:-@}"
    ;;
  remove)
    [ $# -eq 2 ] || usage
    case "$2" in
      */*) remove "$2" ;;
      *) remove "$(repo_dir)/$2" ;;
    esac
    ;;
  *) usage ;;
esac
