---
name: jj
description: Use for any task that inspects or rewrites this repository's history or working copy — even when the user never says "git" or "jj". Trigger when they want to: commit, describe, or amend work; split, reorder, squash, or move changes within a stack; absorb loose hunks into the ancestor that introduced them; restore a file's contents from an earlier change; create or move bookmarks/branches; fetch, or fix a push that reports "nothing to push"; rebase a stack and resolve the resulting conflicts in place; or inspect the operation log to undo a bad rebase or operation. This user mandates Jujutsu (jj) over git for all such work — consult this skill for the jj approach before acting. Do NOT trigger for merely reading dependency metadata (flake.lock pinned revisions, an upstream project's git submodules or tags), diffing NixOS generations, or gh CLI PR/issue tasks — those are not local version-control operations.
---

# Jujutsu (jj) — replaces git for this user

Jujutsu is a git-compatible VCS. Repositories are colocated (`jj git init
--colocate`), so `.git` exists, but operations must go through `jj`. Fall
back to `git` only for the documented exceptions (`git rev-parse`,
LFS/submodules, CI scripts already shelling out to git, the `gh` CLI).

## Mental model — read before doing anything

- The **working copy is always a commit**, called `@`. Its parent is `@-`.
  Editing files mutates `@` automatically — there is no staging area, no
  index, no `git add`, no stash.
- Every change has two IDs:
  - **Change ID** (reversed-alphabet letters, e.g. `puqltutt`): stable
    across rewrites — use it when referring to a change over time.
  - **Commit ID** (hex, e.g. `f7fb5943`): changes when content changes.
  - Both accept prefix-match anywhere a revision is expected.
- **Bookmarks** (jj's word for branches) are pointers that do *not*
  auto-advance on commit. After `jj commit`, run
  `jj bookmark set NAME -r @-` to move the bookmark forward.
- Most commands accept a **revset** via `-r` (e.g. `@`, `@-`, `main..@`,
  `trunk()..@`, `mine()`). The query language is small but distinctive —
  see `references/revsets.md`.
- **Conflicts are first-class.** A commit can be in a conflicted state and
  you can keep working. The resolution pattern is unusual; see
  `references/conflicts.md`.
- **`jj undo` walks the operation log.** Almost every local operation is
  reversible — `jj op log` shows them.

## Running jj from Claude Code

- jj pages its output by default. For any command whose output you need to
  capture (log, diff, show, op log), pass `--no-pager` (preferably right
  after `jj`: `jj --no-pager log`), otherwise the tool result is empty. Do
  **not** use `JJ_PAGER=cat jj …`: the env-var prefix is not in the harness
  allowlist and will prompt every single time. Only the plain `jj <cmd>`
  and `jj --no-pager <cmd>` forms are pre-approved.
- jj snapshots the working copy on every command. After editing files, the
  next `jj st` or `jj diff` already reflects the change. No explicit add.
- **Mutating commands are not pre-approved** in the harness (`commit`,
  `describe`, `squash`, `rebase`, `abandon`, `restore`, `bookmark set/move`,
  `git push`). They prompt; confirm the plan with the user first.
- `jj git push` and `jj op abandon` are explicitly **denied** — never
  suggest running them, let the user invoke them.
- Before any mutation, run `jj st` and `jj --no-pager log` so you and the
  user share the same picture of the graph.

## Quick translation cheatsheet

| Intent                          | git                                | jj                                          |
|---------------------------------|------------------------------------|---------------------------------------------|
| Working copy state              | `git status`                       | `jj st`                                     |
| History graph                   | `git log --oneline --graph`        | `jj log`                                    |
| Diff working copy               | `git diff`                         | `jj diff`                                   |
| Diff a commit                   | `git show <sha>`                   | `jj show <rev>`                             |
| Stage + commit (one shot)       | `git add . && git commit -m "..."` | `jj commit -m "..."`                        |
| Reword current change           | `git commit --amend -m "..."`      | `jj describe -m "..."`                      |
| Amend content (no command!)     | `git add . && git commit --amend`  | just edit — `@` already reflects changes    |
| New empty change on top         | `git commit --allow-empty`         | `jj new -m "..."`                           |
| Squash @ into parent            | `git commit --amend --no-edit`     | `jj squash`                                 |
| Squash into a specific commit   | (interactive rebase)               | `jj squash --into <rev>`                    |
| Split a change                  | `git reset -p` + recommit          | `jj split`                                  |
| Edit an older commit            | `git rebase -i` reword/edit        | `jj edit <rev>`                             |
| Cherry-pick                     | `git cherry-pick <sha>`            | `jj duplicate <rev> -d @`                   |
| Rebase a stack                  | `git rebase --onto x y`            | `jj rebase -s <rev> -d <new-parent>`        |
| Abandon a commit                | `git reset --hard HEAD~`           | `jj abandon <rev>`                          |
| Undo the last operation         | `git reflog` + reset               | `jj undo`                                   |
| Fetch                           | `git fetch`                        | `jj git fetch`                              |
| Push a bookmark                 | `git push origin x`                | `jj git push --bookmark x`                  |
| Create a bookmark               | `git switch -c name`               | `jj bookmark create name -r @`              |
| Move a bookmark forward         | `git branch -f name HEAD`          | `jj bookmark set name -r @-`                |
| Operation log (reflog)          | `git reflog`                       | `jj op log`                                 |

For the long form of any row — flags, edge cases, related commands — see
`references/workflows.md`.

## Bookmarks: the most-missed gotcha

After `jj commit -m "..."`, the bookmark you were "on" did **not move** —
you did. `@` is now a new empty change one above the bookmark. To push,
you have to advance it first:

```
jj commit -m "feat: foo"
jj bookmark set my-feature -r @-      # ← easy to forget
# Now push (user-driven, gated):
# jj git push --bookmark my-feature
```

If `jj git push` reports "nothing to push", this is almost always the
reason. jj only pushes bookmarks (or `--change`, which fabricates one).

## Conflicts in one paragraph

A rebase or merge that produces a conflict leaves the conflicted commit in
place — `jj log` annotates it `(conflict)`. To fix it, create a working-copy
commit on top of the conflicted change (`jj new <conflicted-rev>`), edit
the file (jj writes git-style markers plus a `%%%%%%%` / `+++++++` diff
block showing what each side changed) or run `jj resolve`, then
`jj squash` to fold the resolution back. Full walkthrough and tooling notes
in `references/conflicts.md`.

## When in doubt

- `jj help <command>` is short and accurate. `jj <cmd> --help` works too.
- `jj op log` shows every operation; `jj undo` reverses the last one.
- Prefer small, frequent `jj commit`s — you can always `jj squash` later.
- If a planned action mutates history, run `jj st` and
  `jj --no-pager log` first and confirm with the user.

## Reference files

Load these when the task calls for them — don't read them upfront.

- `references/revsets.md` — full revset language (operators, predicates,
  common queries). Read when selecting commits by anything beyond `@`,
  `@-`, or a single change ID.
- `references/workflows.md` — full command tables and recipes for
  remote sync, rebase variants, bookmark management, restore, duplicate.
  Read when the cheatsheet above isn't enough.
- `references/conflicts.md` — conflict markers, `jj resolve` with merge
  tools, alternative `jj edit` workflow, partial resolutions. Read when
  handling a `(conflict)` state.
- `references/advanced.md` — `jj absorb`, `jj fix`, `jj parallelize`,
  `jj diffedit`, `jj workspace`, `jj file annotate/show/list`, log
  templates (`-T`), and `~/.config/jj/config.toml` tips. Read when a task
  calls for something beyond the everyday set.

## Things that don't translate from git

- **No staging area.** No `git add`. Use `jj split` / `jj squash` to slice
  changes after the fact.
- **No stash.** The working copy is already a commit; `jj new` to start
  something else, `jj edit <change-id>` to come back.
- **No detached HEAD.** Every state is a named change with a stable ID.
- **`HEAD` ≈ `@-`** in most git-mental-model translations.
- **Branches don't auto-advance.** Explicit `jj bookmark set` is required.
- **`jj git push` ≠ `git push`.** Only pushes bookmarks (or `--change`).
