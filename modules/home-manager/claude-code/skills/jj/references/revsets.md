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

- `description(substring-i:"x")` — message contains `x`, any case.
  `subject(...)` matches the first line only.
- `description(regex:"pattern")` — same with a regex.
- `author(string)`, `committer(string)` — match author/committer name or email.
- `files("path")` — touched the given path (a fileset; `glob:"src/**"`
  works). `file()` no longer exists.
- `diff_lines(substring:"text" [, files])` — an added or removed line
  matches (git's `-S`/`-G`). `diff_contains` is the deprecated name.
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
| Commits touching a file                   | `files('flake.nix')`                         |
| Commits with "wip" in the message         | `description(substring-i:wip)`               |
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
jj log -r 'description(substring-i:wip)'
jj diff -r '@-'                              # last finalized change
jj log -r 'mine() & ~empty()' -n 3          # last 3 non-empty mine
jj rebase -s 'roots(trunk()..@)' -o 'trunk()'  # rebase a stack
jj log -r 'files("flake.nix") & mine()'      # my changes to a file
```

`jj log` is the usual playground for testing a revset before using it in a
mutating command.

## String patterns

Predicates that take text (`description`, `subject`, `author`,
`bookmarks`, `diff_lines`, …) accept a pattern kind prefix: `exact:`,
`substring:`, `substring-i:`, `glob:`, `regex:`. **Always write the
prefix.** In 0.45 the bare-string default differs between functions: for
`diff_lines` it is a glob that must match the whole line, so
`diff_lines("TODO")` finds nothing while `diff_lines(substring:"TODO")`
works.

## Templates

`-T` controls `jj log` output format — handy for confirming a revset selects
exactly the commits and fields you expect. The full building-block list lives
in `references/advanced.md`; the one you'll reach for most:

```
jj --no-pager log -r 'main..@' \
  -T 'change_id.shortest() ++ " " ++ description.first_line() ++ "\n"'
```
