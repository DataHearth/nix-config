# Revsets — jj's commit query language

Most jj commands that take a revision (via `-r`) accept a revset: a small
expression language for selecting one or many commits. The defaults are
tuned for the common case (`@`, `@-`), but jj's real power shows when you
range over commits explicitly.

## Symbols

- `@` — the working copy.
- `@-` — parent of `@`. `@--` — grandparent. `@+` — child of `@`.
- `root()` — the magic root commit.
- `none()` — empty set. `all()` — every change in the repo.
- `trunk()` — the configured trunk bookmark (usually `main@origin`).
- `mine()` — changes you authored.

## Set operators

- `x | y` — union.
- `x & y` — intersection.
- `~x` — complement (everything *not* in `x`).
- `x ~ y` — set difference (in `x` but not in `y`).
- `(a | b) & c` — parentheses group.

## Graph operators

- `::x` — ancestors of `x`, **inclusive of `x`**.
- `x::` — descendants of `x`, inclusive.
- `x::y` — the DAG range from `x` to `y` (commits reachable from `y` through
  `x`'s descendants).
- `x..y` — the linear range: `y`'s ancestors minus `x`'s. Same as
  `::y & ~::x`. This is the form you want for "what's on this branch but
  not on main".
- `x-` — direct parents of `x`. `x+` — direct children of `x`.
- `heads(x)` — tip commits of `x` (members with no children in `x`).
- `roots(x)` — bottom commits of `x`.

## Predicates (filters)

- `description(substring)` — commits whose message contains `substring`.
- `description(regex:pattern)` — same with a regex.
- `author(string)`, `committer(string)` — match author/committer name or email.
- `file(path)` — touched the given path (glob OK).
- `diff_contains(regex)` — diff content matches.
- `empty()` — commits with no changes (e.g. an empty `@` after `jj commit`).
- `conflicts()` — commits currently in a conflicted state.
- `present(name)` — true if `name` resolves to a single commit.

## Bookmark and tag predicates

- `bookmarks()` — every commit that has any bookmark on it.
- `bookmarks(glob)` — commits with a bookmark matching the glob.
- `remote_bookmarks()` — every remote-tracking bookmark commit.
- `remote_bookmarks(remote=origin)` — restrict to a remote.
- `tags()` — tagged commits.

## Recipes for common questions

| Question                                  | Revset                                       |
|-------------------------------------------|----------------------------------------------|
| What's on my stack vs main?               | `main..@` or `trunk()..@`                    |
| Same, including @                         | `main..@` (already inclusive of @)           |
| Tip of every branch I own                 | `heads(mine())`                              |
| Recent commits I haven't pushed           | `remote_bookmarks()..mine() & ~empty()`      |
| Commits touching a file                   | `file('flake.nix')`                          |
| Commits with "wip" in the message         | `description(regex:wip)`                     |
| Everything not on trunk                   | `~::trunk()`                                 |
| All my conflicted commits                 | `conflicts() & mine()`                       |
| The change one before @                   | `@--`                                        |
| The change two ahead of @                 | `@++`                                        |
| Children of a specific change             | `<rev>+`                                     |
| Ancestors of @ that aren't on main        | `::@ & ~::main` (same as `main..@`)          |

## Using a revset in commands

Most commands take `-r REVSET`. Examples:

```
jj log -r 'main..@'                          # range
jj log -r 'description(regex:wip)' --no-pager
jj diff -r '@-'                              # last finalized change
jj show -r 'mine() & ~empty()' --limit 3     # last 3 non-empty mine
jj rebase -s 'wq..@' -d 'trunk()'            # rebase a stack
jj abandon -r 'empty() & mine()'             # nuke empty changes I authored
```

`jj log` is the usual playground for testing a revset before using it in a
mutating command. Pipe through `--no-pager` to capture output.

## Templates

`-T` controls `jj log` output format — handy for confirming a revset selects
exactly the commits and fields you expect. The full building-block list lives
in `references/advanced.md`; the one you'll reach for most:

```
jj --no-pager log -r 'main..@' \
  -T 'change_id.shortest() ++ " " ++ description.first_line() ++ "\n"'
```
