# Version control: jj, not git

This user uses Jujutsu (jj) for all version control. Every VCS task —
status, log, diff, commit, describe, bookmark, push, fetch, rebase, merge,
undo, history inspection, conflict resolution — uses `jj`, not `git`.

This is a hard rule, not a preference. Don't fall back to `git` because it
is more familiar. Repos are colocated (`jj git init --colocate`), so a
`.git` directory is present — that does not relax the rule.

The **`jj` skill** is the canonical reference: a lean `SKILL.md` plus
`references/` for revsets, workflows, conflicts, and advanced commands.
Consult it before running unfamiliar jj commands. Skill loading is
progressive — load a reference file only when the task actually calls
for that area (revset construction, conflict resolution, etc.).

Permitted git exceptions (jj has no equivalent):
- Raw git plumbing (`git rev-parse`, `git config` for remotes)
- LFS / submodule operations
- CI scripts and tooling that already shell out to git
- The `gh` CLI (PRs, issues) — jj does not replace it

`jj git push` and `jj op abandon` are explicitly denied in the harness.
Confirm push plans with the user and let them invoke push themselves.

# NixOS system

This machine runs NixOS. Software is managed declaratively, so binaries are
not installed ad hoc with apt/brew/pip. To run a tool that is not already on
PATH — i.e. not provided by the project's root flake (devShell, packages, or
apps) — use `nix run` instead of expecting it to be installable:

    nix run nixpkgs#<package> -- <args>

Do not suggest `apt install`, `brew install`, `pip install --user`, or other
imperative installs. If a tool will be used repeatedly, prefer adding it to
the appropriate nix configuration; for one-off invocations, `nix run` is fine.

# Temporary files and directories

When you need scratch space (downloaded archives, intermediate output, dumps
for inspection, log captures), it **MUST** go in a **project-scoped
subdirectory of `/tmp`** — never directly in `/tmp` and never in the project
tree:

    /tmp/<project>/...

where `<project>` is the basename of the current working directory (e.g.
`/tmp/nix-config/` when working in `~/.config/nix-config`). `mkdir -p` it on
first use. This is a hard rule, not a default: every downloaded, generated,
or intermediate file lands under `/tmp/<project>/`.

Why a per-project subdir:
- Keeps unrelated tasks from colliding on the same filenames.
- Easy to wipe (`rm -rf /tmp/<project>`) without touching other scratch.
- Lets permission rules be scoped narrowly (`Read(/tmp/<project>/**)`,
  `Write(/tmp/<project>/**)`) instead of granting `/tmp/**` blanket access.

The grant model follows from this: the `/tmp/<project>/` subdirectory gets
full `Read` + `Write` + `Edit` access (the recursive `/tmp/<project>/**`
form — see the `Read(~/.config)` note: a bare directory path does not cover
its contents), while `/tmp` itself is **not** granted. Never request or rely
on a blanket `Read(/tmp/**)` / `Write(/tmp/**)`; scope every tmp permission
to the project subdir.
