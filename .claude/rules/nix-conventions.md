When working with Nix files in this repository:
- Use SRI hashes: `hash = "sha256-..."` or explicit `sha256 = "hex..."`. Never use bare hex with `hash =`.
- Desktop files: use `install -Dm444` for proper permissions, not `cp` + `mkdir -p`.
- Build with `nh os build` (or `nh os switch`), never raw `nix build` expressions.
