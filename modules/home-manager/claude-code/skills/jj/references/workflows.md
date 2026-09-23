# Workflows and full command tables

The tables in `SKILL.md` cover the common case. This file fills in flags,
edge cases, and multi-step recipes. Flags are checked against jj 0.45.

## Inspecting state

| Intent                  | Command                                 |
|-------------------------|-----------------------------------------|
| Working copy status     | `jj st`                                 |
| History (default view)  | `jj log`                                |
| Everything              | `jj log -r 'all()'`                     |
| Last N                  | `jj log -n 10`                          |
| No graph, one line each | `jj log --no-graph -T 'change_id.shortest() ++ " " ++ description.first_line() ++ "\n"'` |
| Diff working copy       | `jj diff`                               |
| Diff a commit           | `jj show <rev>` / `jj diff -r <rev>`    |
| Diff a range            | `jj diff --from A --to B`               |
| Stat / summary / names  | `--stat`, `--summary`, `--name-only`    |
| git-format patch        | `jj diff --git`                         |
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
| Set message of `@`                  | `jj describe -m "msg"`                   |
| Set message of another rev          | `jj describe <rev> -m "msg"`             |
| Open the next change                | `jj new` / `jj new -m "msg"`             |
| New child of a specific rev         | `jj new <rev> -m "msg"`                  |
| Insert a new change mid-stack       | `jj new -A <rev>` / `jj new -B <rev>`    |
| Merge (multiple parents)            | `jj new a b -m "merge"`                  |
| Squash `@` into parent              | `jj squash`                              |
| Squash `@` into a specific commit   | `jj squash --into <rev>`                 |
| Move content between commits        | `jj squash --from <src> --into <dst>`    |
| Squash only some files              | `jj squash [--into <rev>] file1 file2`   |
| Keep destination's message          | `jj squash -u`                           |
| Keep the emptied source             | `jj squash -k`                           |
| Pipe a message in                   | `jj describe --stdin`                    |

The user seals work with `jj describe -m` + `jj new`, not `jj commit`.
`jj commit -m` does the same in one step; use it only if asked.

`jj squash` opens an editor only when *both* source and destination already
have a description. Pass `-m "msg"` or `-u` to avoid it.

`jj squash <path>` moves the **whole file's** diff. To move only one hunk
of a file into another change, revert that hunk in `@`, squash the rest,
then re-apply the hunk.

## Splitting

Always by fileset — the default `jj split` opens a diff editor.

```
jj split src/foo.rs src/bar.rs -m "first: the named paths"
jj describe -m "second: the remainder"        # @ is now the remainder
```

| Flag           | Effect                                                                                  |
|----------------|-----------------------------------------------------------------------------------------|
| `<filesets>`   | These paths go into the **selected** (first) commit; the rest stays in the remainder    |
| `-m "msg"`     | Describes the selected commit only — the remainder keeps the original message           |
| `-r <rev>`     | Split a revision other than `@`                                                          |
| `-p`           | Make the two parts siblings instead of parent/child                                      |
| `-o <rev>`     | Put the selected paths in a new commit **onto** `<rev>` — e.g. `-o 'trunk()'` to lift a fix out of a WIP pile as a sibling of trunk |
| `-A` / `-B`    | …inserted **after** / **before** `<rev>`                                                  |

If every change matches the fileset, jj warns "All changes have been
selected, so the original revision will become empty". That's fine: the
original is left as an empty `@`.

## Bookmarks (branches)

| Intent                       | Command                                       |
|------------------------------|-----------------------------------------------|
| Create                       | `jj bookmark create name -r <rev>`            |
| Create or move               | `jj bookmark set name -r <rev>`               |
| Move backwards/sideways      | `jj bookmark set name -r <rev> --allow-backwards` |
| Move all bookmarks from revs | `jj bookmark move --from <revs> --to <rev>`   |
| List local                   | `jj bookmark list`                            |
| List with remotes            | `jj bookmark list --all-remotes` (`-a`)       |
| One bookmark, all remotes    | `jj bookmark list name --all-remotes`         |
| Track a remote bookmark      | `jj bookmark track name@origin`               |
| Rename                       | `jj bookmark rename old new`                  |
| Delete / forget / untrack    | `jj bookmark delete|forget|untrack …` (prompt) |
| "Check out" a bookmark       | `jj new name`                                 |

`set` refuses to move a bookmark backwards or sideways. That usually means
the change isn't built on the bookmark's current target, which happens
when the remote moved and you haven't rebased yet. Fetch and rebase
before you reach for `--allow-backwards`.

A **conflicted bookmark** (`name??` in `jj log`, "(conflicted)" in the
list) has several targets at once, usually local vs remote after a fetch.
Pick one: `jj bookmark set name -r <rev>`.

## Remote sync

| Intent                     | Command                                          |
|----------------------------|--------------------------------------------------|
| Fetch                      | `jj git fetch` (runs unprompted)                 |
| Fetch one branch           | `jj git fetch -b name`                           |
| Fetch from a remote        | `jj git fetch --remote origin`                   |
| Push one bookmark          | `jj git push -b name`                            |
| Push a new bookmark        | `jj git push -b name` (no extra flag in 0.45)    |
| Create + push in one go    | `jj git push --named name=<rev>`                 |
| Push by change (auto name) | `jj git push -c <rev>`                           |
| Push a tag                 | `jj git push -t v1.2.3`                          |
| Preview                    | `jj git push -b name --dry-run`                  |
| Pull (fetch + rebase)      | `jj git fetch && jj rebase -b @ -o 'trunk()'`    |

**Not flags in 0.45:** `--allow-new`, `--allow-backwards` (that one belongs
to `bookmark set`), `--force`. Push already uses force-with-lease: it
refuses if the remote moved since the last fetch ("stale info").

`jj git push` prompts. Before running it, state which bookmark goes to
which commit and whether that is a fast-forward. Pushing tracked
bookmarks needs no `--remote` unless the repo has several remotes.

## Rebase, restore, duplicate

| Intent                         | Command                                  |
|--------------------------------|------------------------------------------|
| Rebase one rev                 | `jj rebase -r <rev> -o <new-parent>`     |
| Rebase rev and descendants     | `jj rebase -s <rev> -o <new-parent>`     |
| Rebase whole branch            | `jj rebase -b <rev> -o <new-parent>`     |
| Insert into a stack            | `jj rebase -r <rev> -A <after>` / `-B <before>` |
| Drop commits that became empty | add `--skip-emptied`                     |
| Cherry-pick                    | `jj duplicate <rev> -o <dest>`           |
| Restore file from parent       | `jj restore FILE`                        |
| Restore from a specific rev    | `jj restore --from <rev> FILE`           |
| Put a rev's content into another | `jj restore --from A --into B [FILE]`  |

- `-r REV` moves just `REV`; its children are reparented onto its old
  parent.
- `-s REV` moves `REV` and everything descending from it.
- `-b REV` moves the whole branch containing `REV`, i.e. everything not
  already on the destination.

`jj abandon` is **denied** to Claude. Hand it over as `! jj abandon <rev>`,
after showing `jj diff -r <rev> --stat` so the user can see what it holds.

## Rewriting an already-pushed commit

Commits reachable from `main@origin` are immutable. Don't `jj edit
--ignore-immutable X`: the next snapshot forks a new child instead of
amending X. Instead:

```
jj new X                                  # edit on top of it
# …make the fix…
jj squash --ignore-immutable -m "msg"     # fold into X; descendants rebase
jj bookmark set main -r <new tip>
jj git push -b main                       # force-with-lease; user must agree
```

Only with explicit consent: this rewrites published history.

## Integrating subagent / worktree commits

`jj duplicate <agent-commit> -o <stack-tip>` copies the agent's work in
without touching its branch. Run `jj new <tip>` before editing, then check
`jj log` to confirm `@` really moved. A failed `jj new` means the next
`jj squash` folds into the wrong parent. Don't rewrite ancestors that an
agent's branch is still based on while it runs; its commit ends up
orphaned.

## Undo and recovery

| Intent                       | Command                                  |
|------------------------------|------------------------------------------|
| Undo last operation          | `jj undo` (prompts)                      |
| Show the op log              | `jj op log`                              |
| Inspect repo at an old op    | `jj --at-op <op-id> log`                 |

`jj op restore` and `jj op abandon` are **denied**. To go back several
operations, run `jj undo` repeatedly, or give the user
`! jj op restore <op-id>`.
