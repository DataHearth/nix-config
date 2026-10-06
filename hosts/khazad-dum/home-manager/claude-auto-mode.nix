{
  # Suspends every Bash allow rule while auto mode is active, so the classifier
  # sees each command. Without it, `Bash(nix run *)` and friends resolve before
  # the classifier and hand out arbitrary code execution unexamined. Costs a
  # classifier call per shell command.
  classifyAllShell = true;

  # Every list keeps "$defaults" so the built-in rules and the dynamically
  # resolved slots (trusted repo, repository visibility, source control) still
  # apply to whichever repo the session starts in. Dropping it would replace
  # the whole section, including the force-push, `curl | bash` and
  # data-exfiltration rules.
  #
  # Per-repository facts are one entry each, keyed by absolute path. They must
  # never be written as repeated `**Slot**: …` labels: the list is global and
  # flat, so a second `**Repository visibility**` line does not override the
  # first — the classifier reads both and gets contradictory context in every
  # session, whichever repo it is actually in.
  environment = [
    "$defaults"

    "Primary use of Claude Code: NixOS/Home Manager configuration for this machine (khazad-dum), plus software development in Go, TypeScript/Svelte, Python and Nix. The per-repository entries below are keyed by absolute path; the repository a session starts in is the trusted one."
    "Source control: github.com/DataHearth (the user's own account) and github.airbus.corp (Airbus GitHub Enterprise, reachable only over the Airbus F5 VPN). Repositories under any other owner are third-party, even when cloned locally."

    "Repo /home/datahearth/.config/nix-config: github.com/DataHearth/nix-config, public, push allowed. Managed with jj. sops-nix encrypted material under secrets/."
    "Repo /home/datahearth/Development/streamline: github.com/DataHearth/streamline, public, push allowed on origin. The `fork` remote is github.com/aslafy-z/streamline, a third party's fork — never push there. Go + Svelte, Taskfile-driven, Helm chart under deploy/."
    "Repo /home/datahearth/Development/flowin: github.com/DataHearth/flowin, private, push allowed."
    "Repo /home/datahearth/Development/nix-flake-templates: github.com/DataHearth/nix-flake-templates, public, push allowed."
    "Repo /home/datahearth/Development/nixpkgs: origin is the user's own public fork github.com/DataHearth/nixpkgs (push allowed); the `upstream` remote is github.com/NixOS/nixpkgs, which the user cannot push to — never push there."
    "Repo /home/datahearth/Development/infra: github.com/Xide/infra, private, push allowed. The user's homelab — Kubernetes cluster, GitOps manifests, sops-encrypted cluster secrets. Changes here reach live services."
    "Repo /home/datahearth/Development/open-design: github.com/nexu-io/open-design, public, the user has no push access — contribute by fork and pull request only."
    "Repo /home/datahearth/Development/DVR-Scan: github.com/Breakthrough/DVR-Scan, a third party's public upstream with no push access — a local clone for reading and building only."
    "Everything under /home/datahearth/Development/airbus is Airbus work and Airbus-confidential."
    "Repo /home/datahearth/Development/airbus/rag: github.airbus.corp/Airbus/EF73-MAP-GRAPH-RAG, Airbus internal, push allowed over the VPN."
    "Repo /home/datahearth/Development/airbus/DDD: a local jj/git repo with no remote configured."
    "Directory /home/datahearth/Development/airbus/eTLM: a container directory, not a repo. The work lives in four sibling repos below it, each with its own remote on github.airbus.corp."
    "Repo /home/datahearth/Development/airbus/eTLM/api: github.airbus.corp/Airbus/0bbe-rgwonprem-etlm-api, Airbus internal, push allowed over the VPN. Go + Taskfile; k8s/kubeconfig is a live cluster credential."
    "Repo /home/datahearth/Development/airbus/eTLM/infra: github.airbus.corp/Airbus/0bbe-rgwonprem-infra, Airbus internal, push allowed over the VPN. Ansible; inventory/prod.ini names production hosts."
    "Repo /home/datahearth/Development/airbus/eTLM/machines-state: github.airbus.corp/Airbus/0bbe-rgwonprem-init, Airbus internal, push allowed over the VPN."
    "Repo /home/datahearth/Development/airbus/eTLM/smcroute-rpm: github.airbus.corp/Airbus/0bbe-rgwonprem-smcroute-rpm, Airbus internal, push allowed over the VPN."
    "The `public` remote in /home/datahearth/Development/airbus/eTLM/api and /home/datahearth/Development/airbus/eTLM/infra points at github.com/aslafy-z/archive-etlm-api and github.com/aslafy-z/archive-etlm-infra — private repos in a third party's personal GitHub account, off Airbus infrastructure. A repo's configured remotes are trusted by default; these two are not."
    "Repo /home/datahearth/Development/divers: a local scratch git repo with no remote."

    "Trusted internal domains: *.nerds.casa (the user's homelab, split-horizon DNS resolved on the LAN); *.airbus.corp, including github.airbus.corp and the internal Artifactory, reachable only over the Airbus F5 VPN."
    "Key internal services: the homelab Kubernetes cluster behind *.nerds.casa, managed from /home/datahearth/Development/infra; Airbus Jenkins and Artifactory, reached from /home/datahearth/Development/airbus (see refresh-jenkins-cookie.py in eTLM and utils/docker_artifactory in rag)."
    "Internal package registry: the Airbus Artifactory for anything under /home/datahearth/Development/airbus — an install in those repos that bypasses it for a public registry is suspicious."
    "Secrets management: sops. /home/datahearth/.config/nix-config holds encrypted material under secrets/ with .sops.yaml and decrypts at build time; /home/datahearth/Development/infra holds infra/cluster/secrets.enc.yaml, infra/cluster/machine-secrets.enc.yaml and infra/cluster/kubeconfig.enc. Decrypted plaintext belongs in neither a worktree nor terminal output."
    "Sensitive data locations & audiences: /home/datahearth/Development/airbus/eTLM/infra/inventory/prod.ini and api/k8s/kubeconfig; /home/datahearth/Development/infra/infra/cluster/kubeconfig, its *.enc.yaml files, and gitops/*/secrets; deploy/.env in /home/datahearth/Development/streamline and /home/datahearth/Development/open-design; .env in /home/datahearth/Development/flowin and /home/datahearth/Development/divers. None of it may leave this machine."
    "Sensitive remote targets, additional to the default prod-name heuristic: every host defined by /home/datahearth/Development/airbus/eTLM/infra/inventory/prod.ini, and the homelab Kubernetes cluster reached from /home/datahearth/Development/infra."
    "Protected IaC scopes: /home/datahearth/Development/airbus/eTLM/api/internal/k8s/** and /home/datahearth/Development/airbus/eTLM/infra/**; /home/datahearth/Development/infra/infra/** and /home/datahearth/Development/infra/gitops/** (a live cluster); /home/datahearth/Development/streamline/deploy/helm/**."
    "Trusted local paths: /home/datahearth/Documents/obsidian-wiki-vault — the user's Obsidian vault, not a git repository, and the routine destination for notes written by the wiki-capture skill."
  ];

  allow = [
    "$defaults"
    "Routine local development in any repository on this machine: jj status/log/diff/show/describe/new/squash/split/absorb/rebase, nix build/eval/flake, task build/test/lint/fmt, and nh os build. These are local and reversible and reach nothing outside the machine."
  ];

  soft_deny = [
    "$defaults"
    "Never push, force-push, or otherwise write to a remote the user has no push rights to: github.com/NixOS/nixpkgs (the upstream remote in /home/datahearth/Development/nixpkgs), github.com/aslafy-z/streamline (the fork remote in /home/datahearth/Development/streamline), github.com/Breakthrough/DVR-Scan, and github.com/nexu-io/open-design."
    "Never decrypt sops-managed secrets into a plaintext file in a worktree, and never print their decrypted contents, in /home/datahearth/.config/nix-config or /home/datahearth/Development/infra."
    "Pushing from /home/datahearth/Development/airbus/** to a github.com remote moves Airbus-internal code off Airbus infrastructure into a third party's personal account. This covers the `public` remotes github.com/aslafy-z/archive-etlm-api and github.com/aslafy-z/archive-etlm-infra. Require the user to name that push."
  ];

  hard_deny = [
    "$defaults"
    "Never send the contents of /home/datahearth/Development/airbus/** to a public paste or gist service, a third-party API, or any other host outside airbus.corp. Pushes to the archive remotes on github.com are governed by the soft block instead, which the user's explicit intent can clear."
  ];
}
