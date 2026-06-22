# Conflicts in jj

Conflicts in jj live **inside commits**, not just in the working copy. A
commit can carry an unresolved conflict and you can keep working with it.
This is the single biggest difference from git's "stop the world, resolve
or `--abort`" model — and the source of most confusion when porting habits.

## How conflicts arise

Anything that rewrites or moves a commit can introduce a conflict:

- `jj rebase` whenever a rebased change can't apply cleanly.
- `jj squash` when merging two divergent contents.
- `jj new` from multiple parents whose contents disagree.
- `jj abandon` of a parent change whose descendants relied on its content.

The conflicted commit stays in place. `jj log` annotates it `(conflict)`.
`jj st` prints "Warning: There are unresolved conflicts at these paths".

## The conflict resolution pattern

The canonical flow is **new-on-top, resolve, squash back**:

```
jj new <conflicted-rev>           # working-copy commit on top of the mess
# Edit the file(s) to resolve, OR run `jj resolve` for an external tool.
jj diff                           # inspect the resolution
jj squash                         # fold the resolution into the conflicted commit
```

Why new-on-top? Because the conflicted commit's state is still a "valid"
commit in jj's eyes — a thing with conflict markers baked in. You're
making a child change that turns those markers into resolved content,
then squashing that child back into the parent.

## Conflict markers

When jj writes a conflicted file to the working copy, it uses a richer
format than git's. A typical 2-sided rebase conflict looks like:

```
<<<<<<< Conflict 1 of 1
%%%%%%% Changes from base to side #1
-original line
+side #1 line
+++++++ Contents of side #2
side #2 contents
>>>>>>> Conflict 1 of 1 ends
```

- The `%%%%%%%` block is a **diff** showing what side #1 changed relative
  to the merge base.
- The `+++++++` block is the **raw contents** of side #2.

The asymmetric format reflects jj's algorithm: it represents one side as a
diff against the base and the other as a snapshot. It's intentional and
preserves more information than git's symmetric `<<<` / `===` / `>>>`.

To resolve, replace the entire `<<<<<<<` … `>>>>>>>` block with the final
content you want. You can resolve partially — leaving some conflict
markers and replacing others — and re-save; jj will keep tracking the
remaining ones.

## Using `jj resolve`

`jj resolve` opens the configured 3-way merge tool on each conflicted file.

```
jj resolve                  # all conflicted files
jj resolve PATH             # a specific file
jj resolve --list           # show which files are conflicted, do nothing
```

**In this harness the bare `jj resolve` hangs** — it launches an interactive
merge tool with no inline escape. Only `jj resolve --list` is safe to run (it
just reports). To actually resolve, edit the conflict markers in the file by
hand (see above), then `jj squash`. Reach for `jj resolve` only when you're
driving jj at a real terminal.

It only handles 2-sides-plus-base conflicts. Conflicts between files and
directories, or symlinks vs files, need manual editing.

The merge tool is configured in `~/.config/jj/config.toml` under
`[merge-tools]`. If none is set, jj falls back to `meld`, `kdiff3`, etc.;
otherwise edit the markers by hand.

## Alternative: edit the commit directly

Instead of new-on-top + squash, you can put yourself *inside* the
conflicted commit:

```
jj edit <conflicted-rev>
# Resolve in place. Save. The commit is no longer conflicted.
```

The downside: you can't inspect the resolution as a diff before
committing to it. Prefer new-on-top for any non-trivial conflict; use
`edit` for tiny single-file fixes.

## Partial resolution

You don't have to resolve everything in one go. Leave some conflict
markers, fix others, save the file. `jj st` still reports unresolved
conflicts; `jj diff` shows your progress. Continue at your leisure.

This is useful for stacked conflicts: resolve the most upstream one
first, let descendants automatically re-derive their conflict state from
the new base, then handle the rest.

## After resolving

Once `jj st` reports no remaining conflicts:

```
jj squash                          # fold new-on-top into the parent (the common case)
# or, if you used `jj edit` directly, nothing more — the commit is fixed.
```

Descendants that were also conflicted because of this commit will be
re-evaluated. Many will become conflict-free automatically; the rest are
new conflicts you can resolve the same way.

## What you'll see, end to end

```
$ jj rebase -d main
Rebased 3 commits onto destination
3 files were updated; 1 conflict remains in 1 commit
Hint: There are unresolved conflicts at these paths:
flake.nix    2-sided conflict
Hint: To resolve the conflicts, start by creating a commit on top of
the conflicted commit:
  jj new <change-id>
Then use `jj resolve`, or edit the conflict markers in the file directly.

$ jj new <change-id>
$ $EDITOR flake.nix                # remove markers, write the resolution
$ jj diff
M flake.nix
... actual resolution diff ...

$ jj squash
Rebased 2 descendant commits
Working copy now at: ... (empty) (no description set)
```

The `(empty) (no description set)` working-copy that pops up after
`jj squash` is fine — it's just a fresh `@` for your next change.

## Picking sides without merging

If you want to wholesale take one side of a conflict — discard everything
from "their" branch in this file, say — use `jj restore`:

```
jj restore --from <rev-with-the-content-you-want> PATH
```

This bypasses the merge entirely by overwriting the file from another
revision.
