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

# Comments: only where the code cannot speak for itself

Default to no comment. Write one only when someone fluent in the language,
reading the code in front of them, still could not work out *why* it is the
way it is. If clearer code would remove the question — a better name, a
smaller function, a named constant — do that instead of explaining.

Never write these, and delete them from any region being edited:
- Restatements of the code: `# Enable bluetooth` above
  `hardware.bluetooth.enable = true;`
- Labels for the self-evident: `# Fonts` above a list of fonts, `# Imports`
  above the imports
- Section banners that only name a block: `# ── Universal grants ──`,
  `# Web`, `# Nix — build/eval/query`
- Changelog and attribution notes: what a value used to be, who changed it,
  which request it came from. History records that; the file should not.

These earn their place:
- Why a non-obvious choice was made — especially when the obvious
  alternative is wrong, or was tried and failed
- Workarounds: name the upstream bug, the affected version, and the
  condition under which the workaround can be removed
- Ordering constraints and invariants a later edit would silently break
- Traps: where the code reads as doing something other than what it does

Length follows need. A real constraint deserves the four lines it takes to
state properly — the goal is no noise, not no words.

Scope: this governs comments being written, and the parts of a file already
being changed. Do not sweep untouched regions of a file unless a cleanup was
asked for. Doc comments that generate API documentation — nix option
`description`, rustdoc, jsdoc — are out of scope; leave them.
