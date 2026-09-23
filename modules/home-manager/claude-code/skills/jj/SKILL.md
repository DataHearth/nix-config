---
name: jj
description: Jujutsu (jj) is this user's only VCS — git is never used for version control here. Load this BEFORE running any jj command other than st/log/diff, and BEFORE reaching for git to inspect history (git log -S / --grep / -- path, git show rev:file, git blame, git branch --contains, git tag, git mv, git status). Trigger on terse requests such as "describe", "split", "split onto master", "push", "describe and push", "rebase onto main", "create a bookmark", "new revision", "squash into X", "cherry-pick", "undo that"; on any jj push/fetch error (stale info, conflicted bookmark, non-tracking remote bookmark, refusing to move backwards, immutable commit); and on (conflict) after a rebase. Not for reading flake.lock metadata, diffing NixOS generations, or gh PR/issue work.
---

# Jujutsu (jj) — replaces git for this user

Repositories are colocated (`.git` exists) but every VCS operation goes
through `jj`. git is allowed only for plumbing with no jj counterpart
(`git rev-parse`, `git check-ignore`, `git ls-remote`), LFS/submodules,
annotated tags, CI scripts that already shell out to git, and `gh`.

Installed version: **jj 0.45**. Several flags seen in older docs and in
model memory no longer exist — trust the tables here over recall.

## Mental model

- The working copy is a commit, `@`; its parent is `@-`. Edits land in `@`
  on the next jj command. No index, no `git add`, no stash.
- Change IDs (letters, `puqltutt`) survive rewrites; commit IDs (hex) do
  not. Refer to changes by change ID.
- Bookmarks (branches) never move on their own. Moving one is always an
  explicit `jj bookmark set`.
- `trunk()`, tags and **untracked** remote bookmarks are immutable. Any
  rebase/squash/describe touching them fails with "would rewrite immutable
  commits".
- Remote-only bookmarks are addressed as `name@origin`; plain `name` fails
  with "Revision doesn't exist".

## Harness rules

- **Never open an editor.** Every command that writes a description takes
  `-m "…"`: `describe`, `new`, `split`, `commit`, and `squash` when both
  sides are described (or `squash -u` to keep the destination's). Never
  `-i`, `jj resolve`, or `jj diffedit` — they launch interactive tools.
- **Help:** use `jj help <cmd> [sub]` (e.g. `jj help git push`) — it is
  allowlisted for every command. `jj git push --help` / `jj abandon --help`
  instead hit the push/abandon permission rules and prompt or get denied.
  Check this file first; the common flags are all here.
- **Permissions:**
  - Read-only (`st`, `log`, `diff`, `show`, `evolog`, `op log`, `file
    show/list/annotate`, `bookmark list`, `help`) and `jj git fetch` run
    unprompted.
  - Local rewrites (`describe`, `new`, `split`, `squash`, `rebase`,
    `restore`, `duplicate`, `bookmark create/set/move/track`) prompt.
  - `jj git push`, `jj undo`, `bookmark delete/forget/untrack`, `git
    import/export` prompt — state what they will do before running them.
  - **Denied** — hand to the user as `! <cmd>`: `jj abandon`, `jj op
    abandon`, `jj op restore`, `jj util gc`, `jj workspace forget`.
- Run jj from inside the repo directory; don't use `-R`/`--repository`.
- Output is not paged when captured, so `jj log` and `jj --no-pager log`
  both work. Don't prefix env vars (`JJ_EDITOR=…`, `JJ_PAGER=…`) — that
  breaks the allowlist match.

## How this user works

- **Seal with `jj describe -m`, then `jj new`** to open the next change.
  Not `jj commit`.
- **Messages are one line**: a Conventional Commit subject, no body, no
  trailers, no `Co-Authored-By`. Whether a `(scope)` is used varies per
  repo — copy the style of `jj log -r 'trunk()' -n 10`.
- **Split before calling a task done.** If `@` mixes unrelated concerns,
  split by file and describe each piece without waiting to be asked.
- **"split onto master/main"** = extract into a sibling of trunk, not a
  commit stacked on the WIP pile: `jj split -o 'trunk()' <paths> -m "…"`.
- **"push" means the bookmark the change is already on, or trunk.** Don't
  invent a `fix/…` bookmark or PR unless asked. If the target is
  ambiguous, ask which one — the user rejected branch pushes with "why a
  branch?" and "master".
- **Each push needs its own go-ahead.** Saying "push" once doesn't cover
  the next change. If the same message also asks a question, answer it
  before pushing.
- **Unexpected changes in `jj diff` may be the user's parallel edits.** Ask
  before `jj restore`-ing them. An undescribed revision isn't necessarily
  empty — check `jj diff -r <rev> --stat` before calling it disposable.

## Everyday commands

| Intent                              | Command                                                  |
|-------------------------------------|----------------------------------------------------------|
| State                               | `jj st`                                                  |
| Stack vs trunk                      | `jj log -r 'trunk()..@'`                                 |
| Diff `@` / a rev / a range          | `jj diff`, `jj diff -r X`, `jj diff --from A --to B`     |
| Files only                          | `jj diff --stat`, `--summary`, `--name-only`             |
| Seal current change                 | `jj describe -m "type(scope): subject"` then `jj new`    |
| Describe another rev                | `jj describe X -m "…"`                                   |
| New change on trunk                 | `jj new 'trunk()' -m "…"`                                |
| Split by files (rest stays in `@`)  | `jj split <paths> -m "…"` then `jj describe -m "…"` on `@` |
| Split out as sibling of trunk       | `jj split -o 'trunk()' <paths> -m "…"`                   |
| Split another rev                   | `jj split -r X <paths> -m "…"`                           |
| Fold `@` into parent                | `jj squash` (`-u` keeps parent's message)                |
| Move changes into rev               | `jj squash --into X [paths]` / `--from A --into B`       |
| Restore file from rev               | `jj restore --from X <path>`                             |
| Rebase change + descendants         | `jj rebase -s X -o Y`                                    |
| Rebase whole branch onto trunk      | `jj rebase -b @ -o 'trunk()'`                            |
| Move one change                     | `jj rebase -r X -o Y` (also `-A`/`-B` to insert)         |
| Cherry-pick                         | `jj duplicate X -o Y`                                    |
| Edit an older change in place       | `jj new X`, edit, `jj squash`                            |
| Undo last operation                 | `jj undo` (prompts); history in `jj op log`              |

`-o/--onto` is the current name of the destination flag on
`rebase`/`split`/`duplicate`/`squash`; `-d` still parses but is legacy.

`jj split` puts the **named paths** in the first commit (described by
`-m`); the remainder becomes the child `@` and keeps the old description,
so rename it with `jj describe -m`. Splitting part of a file needs the
interactive editor, so it can't be done here. Instead, split whole files,
or edit the file back, squash, and re-apply.

## Bookmarks and pushing

```
jj describe -m "fix(x): …" && jj new           # seal; @ is now empty on top
jj bookmark set main -r @-                     # advance the bookmark
jj git push -b main                            # prompts; explain first
```

- Setting the bookmark on `@` and pushing works too. jj then reports "The
  working-copy commit became immutable; a new commit has been created on
  top". That is harmless: it just opens a fresh `@`.
- New bookmark: `jj bookmark create name -r @-` then `jj git push -b
  name`, or in one go `jj git push --named name=@-`. **There is no
  `--allow-new`** in 0.45; new bookmarks push without it.
- `--allow-backwards` belongs to `jj bookmark set`, not `jj git push`.
- `jj git push -t v1.2.3` pushes a tag. `jj tag set v1.2.3 -r X` creates
  a lightweight tag; annotated tags still need `git tag -a`.

### When a push or bookmark move fails

| Message                                                    | Cause → fix                                                                                          |
|------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| `unexpectedly moved on the remote (reason: stale info)`    | Remote advanced. `jj git fetch`, `jj rebase -b @ -o 'trunk()'`, re-set the bookmark, push.           |
| `Name 'main' is conflicted` / `Bookmark X is conflicted`   | Local and remote diverged after the fetch. Rebase your work onto `X@origin`, then `jj bookmark set X -r <rev>`. |
| `Refusing to move bookmark backwards or sideways`          | Target isn't a descendant of the bookmark — usually you need to rebase onto `X@origin` first. `--allow-backwards` only if moving back is intended. |
| `Non-tracking remote bookmark X@origin exists`             | `jj bookmark track X@origin`, then check `jj bookmark list X --all-remotes` for a conflict.          |
| `would rewrite N immutable commits`                        | Target is trunk, a tag, or an untracked remote bookmark. Track the bookmark, or rebase your own change instead. For already-pushed commits, see `references/workflows.md`. |
| `Nothing changed` / nothing to push                        | The bookmark wasn't moved. `jj bookmark set X -r @-`.                                                 |
| `could not read Username` on fetch/push                    | Needs interactive credentials — hand the command to the user.                                        |

## git history queries → jj

These are the git commands most often reached for by habit. All run
unprompted in jj form.

| git                                    | jj                                                              |
|----------------------------------------|-----------------------------------------------------------------|
| `git log -- path`                      | `jj log -r 'files("path")'`                                     |
| `git log -S str` / `-G re`             | `jj log -r 'diff_lines(substring:"str")'` / `diff_lines(regex:"re")` |
| `git log --grep x`                     | `jj log -r 'description(substring-i:"x")'`                      |
| `git log A..B`, `v3.0.0..HEAD`         | `jj log -r 'A..B'`, `jj log -r 'v3.0.0..@-'`                    |
| `git show rev:path`                    | `jj file show -r rev path`                                      |
| `git show --stat X`                    | `jj show --stat X`                                              |
| `git blame` / `git log -L`             | `jj file annotate path`                                         |
| `git branch -r --contains X`           | `jj log -r 'X:: & remote_bookmarks()'`                          |
| `git tag`                              | `jj tag list`                                                   |
| `git status --porcelain`               | `jj diff --summary`                                             |
| `git ls-files`                          | `jj file list`                                                  |
| `git mv a b`                           | `mv a b` (jj detects the rename)                                |
| `git rev-parse HEAD`                   | `jj log -r @- --no-graph -T commit_id` (or keep git: plumbing)  |

**Always give string patterns an explicit prefix** (`substring:`,
`substring-i:`, `regex:`, `glob:`). In 0.45 a bare string such as
`diff_lines("guard")` is a glob that has to match the whole line, so it
silently returns nothing. `file()` is gone; use `files()`.

## Conflicts

A conflicted commit stays in the graph (`(conflict)` in `jj log`). Resolve
with `jj new <conflicted>`, edit the markers by hand, then `jj squash`.
Resolving the first conflicted ancestor often clears the descendants.
Details in `references/conflicts.md`.

## Reference files

Load only when the task needs them.

- `references/revsets.md` — revset operators, predicates, string patterns,
  recipes.
- `references/workflows.md` — full flag tables: bookmarks, remotes,
  rebase variants, rewriting pushed commits, integrating agent work.
- `references/conflicts.md` — marker format, partial resolution, picking a
  side.
- `references/advanced.md` — `absorb`, `parallelize`, `fix`, workspaces,
  templates (`-T`), config.
