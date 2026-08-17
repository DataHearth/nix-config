# Version control: jj, not git

This user uses Jujutsu (jj) for all version control. Every VCS task —
status, log, diff, commit, describe, bookmark, push, fetch, rebase, merge,
undo, history inspection, conflict resolution — uses `jj`, not `git`.

This is a hard rule, not a preference, and it holds unless the user says
otherwise in the moment. Don't fall back to `git` because it is more
familiar, because a snippet or README spells the task in git, because the
repo looks like a plain git checkout, or because a `git` invocation is one
character shorter. Repos are colocated (`jj git init --colocate`), so a
`.git` directory is present — that does not relax the rule.

If a task seems to need git, the first move is to find the jj equivalent,
not to reach for git and note the exception afterwards. jj covers the whole
surface: `jj st`/`jj log`/`jj diff` for inspection, `jj describe` to seal,
`jj new`/`jj squash`/`jj split`/`jj absorb` to shape a stack, `jj rebase`
to move it, `jj bookmark` for branches, `jj git fetch`/`jj git push` for
the remote, `jj undo` and `jj op log` for recovery. Only when the operation
genuinely has no jj counterpart — the short list below — does git apply.
When unsure whether a counterpart exists, consult the `jj` skill or ask;
do not guess with git.

The **`jj` skill** is the canonical reference: a lean `SKILL.md` plus
`references/` for revsets, workflows, conflicts, and advanced commands.
Consult it before running unfamiliar jj commands. Skill loading is
progressive — load a reference file only when the task actually calls
for that area (revset construction, conflict resolution, etc.).

Permitted git exceptions, and nothing beyond them (jj has no equivalent):
- Raw git plumbing (`git rev-parse`, `git config` for remotes)
- LFS / submodule operations
- CI scripts and tooling that already shell out to git
- The `gh` CLI (PRs, issues) — jj does not replace it

The harness splits the dangerous commands by recoverability.

**Denied outright** — destroys work with no way back. These cannot run in
any permission mode. Propose the command and let the user invoke it with
`!`; do not route around it with a git equivalent or a shell trick.

- jj: `abandon`, `op abandon`, `op restore`, `util gc`, `workspace forget`
- git: `checkout`, `restore`, `clean`, `reset --hard`, `branch -d|-D`,
  `filter-branch`, `gc`, `prune`, `repack`, `reflog delete|expire`,
  `stash drop|clear`, `worktree remove|prune`

**Prompts first** — reaches the remote or the colocated git repo, but stays
recoverable. These run after the user approves the prompt, so propose them
normally rather than handing them off.

- jj: `git push|import|export`, `git remote` writes, `undo`, `op undo`,
  `bookmark delete|forget|untrack`
- git: `push`, `fetch`, `pull`, `rm`, `tag -d`, `update-ref`,
  `remote` writes

Everything else in jj stays available and unprompted — `describe`, `new`,
`squash`, `split`, `rebase`, `absorb`, and `jj git fetch` all run normally.

A prompt is the user's decision point, not a formality: state what the
command will do before running it, especially for anything that reaches the
remote.

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
