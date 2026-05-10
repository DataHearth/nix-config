# Advanced and less-common jj features

Less-used commands and tooling that the cheatsheet skips. Reach for these
when a task explicitly calls for them.

## `jj absorb` — auto-distribute hunks

Takes the hunks in `@` (or `-r REV`) and pushes each one back into the
most recent mutable ancestor that introduced the line being changed. Use
it when you've made a batch of fixups that each belong to a different
earlier commit in your stack.

```
jj absorb            # absorb @ into ancestors
jj absorb -r <rev>   # absorb a different change
```

Hunks that don't match any ancestor (new code, unrelated edits) are left
in `@`. Inspect with `jj diff` afterwards.

## `jj fix` — run a formatter/linter across commits

Runs the configured fix command (formatter, linter, …) on changed files
in a revision and rewrites the commit with the fixed content. Configured
via `[fix.tools]` in `~/.config/jj/config.toml`:

```toml
[fix.tools.rustfmt]
command = ["rustfmt", "--emit=stdout"]
patterns = ["glob:'**/*.rs'"]
```

Then:

```
jj fix           # fix @
jj fix -s <rev>  # fix REV and descendants
```

Useful for retroactively running a formatter across an unmerged stack
without dirtying the working copy.

## `jj parallelize` — turn a chain into siblings

Takes a linear chain of changes and rewrites them so they all share the
chain's first parent — making them siblings. Useful when you have a stack
of independent changes and want to PR them in parallel rather than as a
queue.

```
jj parallelize <rev1>::<rev2>
```

The descendants of the chain are rebased onto each parallelized change as
appropriate.

## `jj diffedit` — interactively edit a commit's diff

Opens the configured diff editor (e.g. meld) on a commit's diff. Whatever
edits you save become the new commit content. Useful for surgically
tweaking what's in a commit without going through `jj edit` + working-copy
edits + `jj squash`.

```
jj diffedit              # edit @
jj diffedit -r <rev>     # edit a specific commit
```

## `jj workspace` — multiple working copies

A workspace is an extra checkout sharing the same repository data — useful
when you want to keep a long-running build going in one tree while editing
in another, without cloning.

```
jj workspace add ../other-tree
jj workspace list
jj workspace forget <name>     # remove a workspace
```

Each workspace has its own `@` change ID. Use `-w` on most commands to
target a specific workspace.

## `jj file ...` — file-level inspection

```
jj file list -r <rev>             # files at a revision
jj file show -r <rev> PATH        # contents of a file at a revision
jj file annotate PATH             # blame, with change IDs
jj file track PATH                # explicitly track (rare; auto by default)
jj file untrack PATH              # mark as untracked (denied here — destructive)
jj file chmod ugo+x PATH          # set executable bit in a commit
```

## Templates (`-T`) — controlling output format

Used by `jj log`, `jj show`, `jj op log`, etc. The template language is
small but expressive. Common building blocks:

- `change_id.short()`, `change_id.shortest()` — change ID.
- `commit_id.short()` — commit hex.
- `description.first_line()`, `description` — message.
- `author.name()`, `author.email()`, `author.timestamp()`.
- `committer.timestamp()`.
- `bookmarks` — bookmarks at this commit.
- `tags` — tags at this commit.
- `empty`, `conflict` — booleans.
- `if(cond, then, else)`, `concat(x, y)` (also `x ++ y`).
- `separate(sep, a, b, c)`.
- `label("color-name", text)` — for colored output.

Quoting: literals are double-quoted; `++` concatenates; whitespace inside
templates is mostly ignored.

A one-line PR summary template:

```
jj --no-pager log -r 'main..@' \
  -T 'change_id.shortest() ++ " " ++ description.first_line() ++ "\n"'
```

For more: `jj help templates`.

## `~/.config/jj/config.toml` — useful settings

```toml
[user]
name = "..."
email = "..."

[ui]
default-command = ["log"]      # `jj` alone runs `jj log`
diff-editor = "meld"
merge-editor = "meld"
paginate = "auto"              # set "never" to drop the pager globally

[revsets]
log = "::@ | (main..)"         # what `jj log` shows by default

[git]
push-bookmark-prefix = "x/"    # `jj git push --change` uses this prefix
private-commits = "description(regex:wip:|tmp:)"  # never push these

[aliases]
l  = ["log", "-r", "main..@"]
ll = ["log", "-r", "::@"]
```

`[revsets].log` is the most impactful setting — it controls which commits
`jj log` shows by default. Tuning it once makes everyday inspection
cleaner.

## Sign-off and commit signing

```
jj sign -r <rev>          # GPG-sign one or more commits
jj unsign -r <rev>        # remove signatures
```

With `[signing]` configured (`backend = "gpg"`, etc.), commits can also
sign automatically on creation.

## `jj git ...` subcommands (the less-used ones)

```
jj git init              # init a new colocated repo
jj git clone <url>       # clone, colocated by default
jj git remote add NAME URL
jj git remote list
jj git remote rename OLD NEW
jj git remote remove NAME
jj git import            # import git refs into jj (useful after raw git ops)
jj git export            # export jj state to git refs
```

`jj git import` / `export` are escape hatches when you've poked at the
underlying git repo with raw `git` and want jj's state to catch up (or
vice versa).
