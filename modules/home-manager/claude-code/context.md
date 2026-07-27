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
