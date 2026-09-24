# Colours stay on the 16 ANSI slots, not truecolor, so the terminal's
# Catppuccin theme decides the actual shades.

# The unit separator, unlike a tab, is not IFS whitespace, so `read` keeps
# empty fields in place instead of collapsing them.
IFS=$'\x1f' read -r cwd model effort ctx five five_reset week week_reset \
  worktree agent pr_number pr_url vim_mode \
  < <(jq -r '
    def pct: if . == null then "" else floor end;
    [
      .workspace.current_dir // .cwd,
      .model.display_name // "",
      .effort.level // "",
      (.context_window.used_percentage // 0 | floor),
      (.rate_limits.five_hour.used_percentage | pct),
      .rate_limits.five_hour.resets_at // "",
      (.rate_limits.seven_day.used_percentage | pct),
      .rate_limits.seven_day.resets_at // "",
      .worktree.name // .workspace.git_worktree // "",
      .agent.name // "",
      .pr.number // "",
      .pr.url // "",
      .vim.mode // ""
    ] | map(tostring) | join("\u001f")
  ')

c() { printf '\033[%sm%s\033[0m' "$1" "$2"; }
sep=$(c 90 ' │ ')

level_colour() {
  if [ "$1" -ge 80 ]; then echo 31; elif [ "$1" -ge 50 ]; then echo 33; else echo 32; fi
}

human_duration() {
  local s=$1
  if [ "$s" -ge 86400 ]; then
    printf '%dd%dh' $((s / 86400)) $((s % 86400 / 3600))
  elif [ "$s" -ge 3600 ]; then
    printf '%dh%dm' $((s / 3600)) $((s % 3600 / 60))
  else
    printf '%dm' $((s / 60))
  fi
}

# Walks up by hand instead of probing with `jj root`/`git rev-parse`, which
# print errors outside a repository. `.jj` is checked first: colocated repos
# carry both, and git's HEAD is always detached there.
vcs_kind="" vcs_root=""
dir=$cwd
while [ -n "$dir" ]; do
  if [ -d "$dir/.jj" ]; then
    vcs_kind=jj vcs_root=$dir
    break
  elif [ -e "$dir/.git" ]; then
    vcs_kind=git vcs_root=$dir
    break
  fi
  [ "$dir" = / ] && break
  dir=$(dirname "$dir")
done

# --ignore-working-copy: a snapshot here would race Claude's own jj commands
# for the working-copy lock on every redraw. The diff counts therefore lag
# edits until the next jj command snapshots.
jj_template='
separate(" ",
  label("diff added", "+" ++ diff.stat().total_added()),
  label("diff removed", "-" ++ diff.stat().total_removed()),
  change_id.shortest(4),
  if(conflict, label("conflict", "conflict")),
  if(divergent, label("divergent", "divergent")),
  if(empty, label("empty", "(empty)")),
  bookmarks,
  if(description,
    label("description", truncate_end(40, description.first_line(), "…")),
    if(!empty, label("description placeholder", "(no description)")),
  ),
)'

case $cwd in
  "$HOME") where="~" ;;
  /) where=/ ;;
  *) where=$(basename "$cwd") ;;
esac
line1=$(c 36 "$where")

case $vcs_kind in
  jj)
    line1+=" $(jj -R "$vcs_root" log -r @ --no-graph --ignore-working-copy --color=always -T "$jj_template")"
    ;;
  git)
    branch=$(git -C "$vcs_root" branch --show-current)
    [ -n "$branch" ] || branch=$(git -C "$vcs_root" rev-parse --short HEAD)
    line1+=" $(c 35 "$branch")"
    ;;
esac

[ -n "$worktree" ] && line1+="$sep$(c 33 "⎇ $worktree")"
if [ -n "$pr_number" ]; then
  pr=$(c 34 "#$pr_number")
  [ -n "$pr_url" ] && pr=$(printf '\033]8;;%s\a%s\033]8;;\a' "$pr_url" "$pr")
  line1+="$sep$pr"
fi
[ -n "$agent" ] && line1+="$sep$(c 35 "@$agent")"

line2=$(c 34 "$model")
[ -n "$effort" ] && line2+=" $(c 35 "$effort")"

filled=$((ctx / 10))
bar=
for i in 1 2 3 4 5 6 7 8 9 10; do
  if [ "$i" -le "$filled" ]; then bar+=▰; else bar+=▱; fi
done
line2+="${sep}ctx $(c "$(level_colour "$ctx")" "$bar $ctx%")"

now=$(date +%s)
limit() {
  local label=$1 used=$2 reset=$3 out
  out="$label $(c "$(level_colour "$used")" "$used%")"
  [ -n "$reset" ] && out+=" $(c 37 "($(human_duration $((reset - now))) left)")"
  printf '%s' "$out"
}
[ -n "$five" ] && line2+="$sep$(limit session "$five" "$five_reset")"
[ -n "$week" ] && line2+="$sep$(limit week "$week" "$week_reset")"

[ -n "$vim_mode" ] && line2+="$sep$(c 33 "$vim_mode")"

printf '%s\n%s\n' "$line1" "$line2"
