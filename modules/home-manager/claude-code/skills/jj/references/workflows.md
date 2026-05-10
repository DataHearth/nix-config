# Workflows and full command tables

The cheatsheet in `SKILL.md` covers the common case. This file fills in
flags, edge cases, and multi-step recipes.

## Inspecting state

| Intent                  | Command                                 |
|-------------------------|-----------------------------------------|
| Working copy status     | `jj st`                                 |
| History (default view)  | `jj log`                                |
| All branches/heads      | `jj log -r 'all()'`                     |
| Compact one-liner       | see template example in `revsets.md`    |
| Diff working copy       | `jj diff`                               |
| Diff a commit           | `jj show <rev>`                         |
| Diff a range            | `jj diff --from A --to B`               |
| Stat-only diff          | `jj diff --stat`                        |
| Per-file blame          | `jj file annotate FILE`                 |
| Show a file at a rev    | `jj file show -r <rev> PATH`            |
| List files in a rev     | `jj file list -r <rev>`                 |
| Operation history       | `jj op log`                             |
| Show one operation      | `jj op show <op-id>`                    |
| Per-change evolution    | `jj evolog -r <rev>`                    |

## Making changes

There is no `git add`. Edits are part of `@` automatically.

| Intent                              | Command                                  |
|-------------------------------------|------------------------------------------|
| Set/edit message of current change  | `jj describe -m "msg"`                   |
| Finalize and start new change       | `jj commit -m "msg"`                     |
| New empty change on top             | `jj new -m "msg"`                        |
| New child of specific rev           | `jj new <rev> -m "msg"`                  |
| Octopus merge (multiple parents)    | `jj new a b c -m "merge"`                |
| Squash @ into parent                | `jj squash`                              |
| Squash @ into a specific commit     | `jj squash --into <rev>`                 |
| Move content between commits        | `jj squash --from <src> --into <dst>`    |
| Squash only some files              | `jj squash file1 file2`                  |
| Use destination's message           | `jj squash --use-destination-message`    |
| Split current change (interactive)  | `jj split`                               |
| Split by path                       | `jj split <path>`                        |
| Edit an older change directly       | `jj edit <rev>`                          |
| Pipe message in                     | `jj describe --stdin`                    |

`jj describe` vs `jj commit`:

- `describe` updates the message of `@`. `@` stays where it is.
- `commit` finalizes `@` (locking content) and puts you on a fresh empty
  `@` on top. Use it when you're done with this change.

## Bookmarks (branches)

Bookmarks point at a commit but do not follow new commits. You must move
them yourself.

| Intent                       | Command                                       |
|------------------------------|-----------------------------------------------|
| Create at @                  | `jj bookmark create name -r @`                |
| Move to a rev                | `jj bookmark set name -r @-`                  |
| Move via from-revset         | `jj bookmark move --from old -t @`            |
| Move sideways or backwards   | add `--allow-backwards`                       |
| List local                   | `jj bookmark list`                            |
| List with remotes            | `jj bookmark list --all-remotes`              |
| Delete (local + mark remote) | `jj bookmark delete name`                     |
| Forget (local only)          | `jj bookmark forget name`                     |
| Rename                       | `jj bookmark rename old new`                  |
| Track a remote bookmark      | `jj bookmark track x@origin`                  |
| Untrack                      | `jj bookmark untrack x@origin`                |
| "Check out" tip              | `jj new name`                                 |
| Edit the bookmark's commit   | `jj edit name`                                |

After `jj commit`, the bookmark you were on did **not** move. Run
`jj bookmark set NAME -r @-` to advance it before pushing.

`jj bookmark set` creates *or* moves. `jj bookmark move` only moves; it
won't create a new bookmark.

## Remote sync

| Intent                | Command                                       |
|-----------------------|-----------------------------------------------|
| Fetch all             | `jj git fetch`                                |
| Fetch one bookmark    | `jj git fetch --branch x`                     |
| Fetch from a remote   | `jj git fetch --remote origin`                |
| Push tracked          | `jj git push` (gated; user-driven)            |
| Push specific         | `jj git push --bookmark x`                    |
| Push new bookmark     | `jj git push --bookmark x --allow-new`        |
| Push by change ID     | `jj git push --change @-`                     |
| Pull (fetch + rebase) | `jj git fetch && jj rebase -d trunk()`        |

`jj git push` uses force-with-lease semantics automatically: it refuses if
the remote moved since the last fetch.

**Push is denied in this environment** — confirm with the user, then let
them run the push themselves.

## Rebase, abandon, restore, duplicate

| Intent                         | Command                                  |
|--------------------------------|------------------------------------------|
| Rebase one rev                 | `jj rebase -r <rev> -d <new-parent>`     |
| Rebase rev and descendants     | `jj rebase -s <rev> -d <new-parent>`     |
| Rebase whole branch            | `jj rebase -b <rev> -d <new-parent>`     |
| Skip emptied commits           | add `--skip-emptied`                     |
| Keep emptied commits           | add `--keep-emptied`                     |
| Cherry-pick                    | `jj duplicate <rev> -d @`                |
| Abandon a commit               | `jj abandon <rev>`                       |
| Keep bookmarks on abandon      | `jj abandon <rev> --retain-bookmarks`    |
| Restore file from parent       | `jj restore FILE`                        |
| Restore from a specific rev    | `jj restore --from <rev> FILE`           |
| Restore the whole change       | `jj restore`                             |

`-r` vs `-s` vs `-b`:

- `-r REV` — just `REV`.
- `-s REV` — `REV` and everything that descends from it.
- `-b REV` — the entire branch containing `REV` (its connected component
  excluding trunk's ancestors).

`jj abandon` is reversible via `jj undo`. Descendants are rebased onto the
abandoned commit's parent. Pass `--restore-descendants` to keep their
content untouched.

## Undo and recovery

| Intent                       | Command                                  |
|------------------------------|------------------------------------------|
| Undo last operation          | `jj undo`                                |
| Show the op log              | `jj op log`                              |
| Show one op                  | `jj op show <op-id>`                     |
| Restore repo to an op        | `jj op restore <op-id>`                  |

`jj op abandon` is **denied** here (it permanently deletes history). Don't
suggest it.

## Common workflows

### Make a commit and push

```
# Edit files, then:
jj commit -m "feat: add foo"
jj bookmark set my-feature -r @-     # advance bookmark
# User runs: jj git push --bookmark my-feature   (gated)
```

### Amend the current change

```
# Edit files — content is already in @, no command needed.
jj describe -m "better message"      # update the message
```

### Start fresh work on top of trunk

```
jj git fetch
jj new trunk() -m "wip: thing"
```

### Split a change

```
jj split              # interactive: pick hunks for the new earlier change
# or by path:
jj split flake.nix
```

### Reorder a stack

```
jj rebase -r <middle-rev> -d <new-parent>
```

### Move a hunk into a different commit

```
# @ has fix-up edits; shove them into an earlier change:
jj squash --into <rev>
# Or only specific files:
jj squash --into <rev> file1 file2
```

### Resolve conflicts after rebase

See `references/conflicts.md` for the full walkthrough.

### Recover from a mistake

```
jj op log              # find the op id you want to undo back to
jj op restore <op-id>  # or: jj undo (last op only)
```
