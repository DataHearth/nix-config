# Workspaces — parallel working copies (replaces `git worktree`)

A workspace is another working copy of the same repo: its own directory,
its own `@`, shared commits, bookmarks and op log. Use one whenever two
lines of work must progress at the same time without touching each
other's files — parallel features, an agent working beside you, a long
build or test run in one tree while you edit another.

`git worktree` is never used here. Workspaces are made and removed with
`claude-jj-workspace`, which is on PATH:

```
claude-jj-workspace add <name> [base]     # prints the new path; base: @
claude-jj-workspace remove <name|path>    # snapshot, forget, delete
```

| git                                   | here                                                 |
|---------------------------------------|------------------------------------------------------|
| `git worktree add -b feat ../feat`    | `claude-jj-workspace add feat 'trunk()'`             |
| `git worktree list`                   | `jj workspace list`                                  |
| `git worktree remove ../feat`         | `claude-jj-workspace remove feat`                    |
| `git worktree prune`                  | `jj workspace forget <name>` for dirs already gone   |
| branch checked out in a worktree      | `feat@` revset (the workspace's `@`)                 |

Prefer the helper over a bare `jj workspace add`. It is the same code
Claude Code's isolation runs, so every workspace:

- lives at `~/.claude/workspaces/<repo>/<name>` — outside the repo tree,
  with `<name>` as the jj workspace name, so `jj log` labels it `<name>@`;
- gets **every gitignored entry up to 10 MB** of the tree it was made
  from (`.env`, kubeconfigs, credential dirs, local config), so it runs
  like the original. Bigger entries — `node_modules`, `.venv`, build
  output, scratch data — are listed in `.jj/skipped-ignored` with the
  source path instead; copy one over when the task needs it;
- has its `.envrc` `direnv allow`ed, so the devShell loads.

A bare `jj workspace add` does none of that; the workspace starts
without `.env` and friends and behaves differently from the original.

## Claude Code isolation is already jj

`claude --worktree`, subagents with `isolation: "worktree"` and background
sessions call the same helper through `WorktreeCreate` / `WorktreeRemove`
hooks:

- The workspace is based on `@` of the session that spawned it: the agent
  sees the in-progress work, including edits not yet described.
- On removal the hook snapshots, forgets the workspace and deletes the
  directory. **The agent's commit survives** in the repo, unlabelled; a
  workspace with no changes leaves nothing behind.
- **Subagent workspaces are never removed** (Claude Code 2.1.282): the
  removal hook doesn't run when a subagent finishes, even if it changed
  nothing. Once you have the agent's change ID, run
  `claude-jj-workspace remove agent-<agentId>` yourself. List leftovers
  with `jj workspace list`.
- Only jj repos get isolation. In a plain git repo creation fails; the
  fix is `jj git init --colocate`, not a manual `git worktree add`.

So request isolation freely; never create a git worktree by hand.

### Working as an isolated agent

The spawning session only gets your final message, and your workspace
label disappears when you finish. Before ending:

1. `jj describe -m "type(scope): subject"` — an undescribed commit is
   hard to tell apart from noise.
2. Leave `@` as that commit (no trailing `jj new`), or split it into a
   small stack if the work has separable parts.
3. Put the change ID(s) in the final message: `Done: kxqpmwvt feat(x): …`.

Stay inside your stack. Don't rebase, describe or squash commits outside
it: they are shared with the spawning session and every sibling agent,
and rewriting them rebases everyone's `@` underneath them.

### Integrating an agent's work

An agent's workspace starts on the spawning session's `@`, so its commit
is normally already a **child of `@`**: the history is in place, but the
files are not in your working copy yet. "Put it on top of my work" means
moving `@`, not the commit:

| Goal                                        | Command                                      |
|---------------------------------------------|----------------------------------------------|
| Continue on top of it (usual case)          | `jj new X` — your WIP stays below as its parent |
| Fold it into the change you're on           | `jj squash --from X --into @`                |
| It sits elsewhere; stack it under `@`       | `jj rebase -r X -A @-`                       |
| Keep it as its own branch                   | `jj bookmark create feat -r X`, push later    |
| Copy it, leave the original                 | `jj duplicate X -o <tip>`                    |

Check with `jj log -r 'X | @ | @-'` first, and confirm afterwards that
its files show in `jj file list -r @`.

Without an ID, find leftovers — heads that no working copy builds on:

```
jj log -r 'heads(mutable()) ~ ::working_copies()'
```

Several agents land as several such heads, often siblings on the same
parent. Bring them in one at a time (`jj new X`, then `jj rebase -r Y -A
@-` for the next), or `jj new X Y` to merge them.

## Manual workspaces for parallel features

```
claude-jj-workspace add feat-auth 'trunk()'
```

- Base: `'trunk()'` for an independent feature, `@` (the default) to build
  on the current work, `@-` for a sibling of `@` without its edits.
- Then work *inside* the printed directory: `cd` into it and run jj
  there, as in any repo. jj acts on the workspace containing the cwd;
  `-R` stays avoided.
- Give each feature its own bookmark once it has a sealed commit
  (`jj bookmark create feat-auth -r @-`), not on the empty starting `@`.

Look at other workspaces from anywhere with the `<name>@` revset:

```
jj workspace list                      # names, paths, @ of each
jj log -r 'working_copies()'           # every workspace's @
jj diff -r feat-auth@ --stat
jj log -r 'trunk()..feat-auth@'
```

There is no `-w`/`--workspace` flag.

### Finishing a workspace

1. Land or keep the work (table above).
2. `claude-jj-workspace remove feat-auth`. It snapshots first, so edits
   made since the last jj command there are kept in the commit, then
   forgets the workspace and deletes the directory.

Forgetting drops the `<name>@` label, not the commit.

## Gotchas

- **Only the original workspace is colocated.** Added ones have `.jj` and
  no `.git`. Tools that shell out to git — including `gh pr create`,
  which reads the current branch — fail there; run them from the main
  workspace, or pass `--repo OWNER/REPO --head <bookmark>`.
- **Never nest a workspace in the repo tree** (e.g. `.claude/worktrees/`).
  git inside it walks up and silently acts on the *main* checkout, and
  Claude Code refuses such a directory for isolation. jj itself copes:
  the outer snapshot skips the nested `.jj` directory.
- **Shared history moves under you.** Rewriting a commit from one
  workspace rebases every workspace whose `@` descends from it. jj
  normally updates the other working copies on their next command; if
  one reports the working copy is stale, run `jj workspace update-stale`
  inside it.
- **Two workspaces, one change.** Don't `jj edit` a commit that is
  another workspace's `@`; both would write to it. Use `jj new X` to
  build on it instead.
- **Copied files are copies.** A `.env` changed in one workspace doesn't
  propagate; re-copy by hand if the original changes mid-feature.
- Bare `jj workspace add` needs the parent directory to exist, and
  without `-r` makes a sibling of `@` rather than a child.
- **Sparse patterns are per workspace**, copied from the current one on
  `add` (`--sparse-patterns full` to reset).
- Other subcommands: `jj workspace root` (this workspace's root),
  `jj workspace rename <new>` (renames the current one).
