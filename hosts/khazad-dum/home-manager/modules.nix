{
  config,
  lib,
  pkgs,
  ...
}:
{
  # zsh-completion-sync enables its "no-caching" optimization by default,
  # which points ZSH_COMPDUMP/_comp_dumpfile at /dev/null. oh-my-zsh's
  # `omz reload` then runs `rm -f /dev/null` and fails with "cannot remove
  # /dev/null". Disabling no-caching gives each shell a real, removable
  # per-shell compdump (under $TMPDIR) so reload works cleanly. The zstyle
  # must be set before the plugin is sourced (home-manager sources zsh
  # plugins at initContent order 900).
  programs.zsh.initContent = lib.mkOrder 850 ''
    zstyle ':completion-sync:compinit:optimizations:no-caching' enabled false
  '';

  home_modules = {
    alacritty.enable = true;
    atuin.enable = true;
    bat.enable = true;
    battery-notify.enable = true;
    direnv.enable = true;
    okular.enable = true;
    theme.enable = true;
    yazi.enable = true;
    zellij.enable = true;

    chromium = {
      enable = true;
      claudeInChrome = true;
      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
        "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite (MV3; classic uBO is MV2, disabled on Chromium 138+)
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
      ];
    };

    zen-browser = {
      enable = true;
      defaultSearchEngine = "startpage";
      searchEngines = {
        "qwant" = {
          urls = [ { template = "https://www.qwant.com/?q={searchTerms}"; } ];
          icon = "https://www.qwant.com/favicon.ico";
          definedAliases = [ "@q" ];
        };
        "startpage" = {
          urls = [ { template = "https://www.startpage.com/sp/search?query={searchTerms}"; } ];
          icon = "https://www.startpage.com/favicon.ico";
          definedAliases = [ "@s" ];
        };
      };
    };

    claude-code = {
      enable = true;

      # "Lazy senior dev" plugin: enforces YAGNI / simplest-solution-that-works.
      # https://github.com/DietrichGebert/ponytail
      plugins.ponytail = pkgs.fetchFromGitHub {
        owner = "DietrichGebert";
        repo = "ponytail";
        rev = "v4.7.0";
        hash = "sha256-Q6vlkbTfBFrNFTxEwYeMe5ciOe6QdULegvExwT//gJs=";
      };

      mcpServers = {
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp";
          headers = {
            Authorization = "Bearer \${GITHUB_TOKEN}";
          };
        };
        context7 = {
          type = "http";
          url = "https://mcp.context7.com/mcp";
          headers = {
            CONTEXT7_API_KEY = "\${CONTEXT7_API_KEY}";
          };
        };
        claude-design = {
          type = "http";
          url = "https://api.anthropic.com/v1/design/mcp";
        };
      };

      # Appended to the module's global context.md; machine-specific rules only.
      context = ''
        # NixOS system

        This machine runs NixOS. Software is managed declaratively, so binaries
        are not installed ad hoc with apt/brew/pip. To run a tool that is not
        already on PATH — i.e. not provided by the project's root flake
        (devShell, packages, or apps) — use `nix run` instead of expecting it to
        be installable:

            nix run nixpkgs#<package> -- <args>

        Do not suggest `apt install`, `brew install`, `pip install --user`, or
        other imperative installs. If a tool will be used repeatedly, prefer
        adding it to the appropriate nix configuration; for one-off invocations,
        `nix run` is fine.

        # Temporary files and directories

        When you need scratch space (downloaded archives, intermediate output,
        dumps for inspection, log captures), it **MUST** go in a
        **project-scoped subdirectory of `/tmp`** — never directly in `/tmp` and
        never in the project tree:

            /tmp/<project>/...

        where `<project>` is the basename of the current working directory (e.g.
        `/tmp/nix-config/` when working in `~/.config/nix-config`). `mkdir -p`
        it on first use. This is a hard rule, not a default: every downloaded,
        generated, or intermediate file lands under `/tmp/<project>/`.

        Why a per-project subdir:
        - Keeps unrelated tasks from colliding on the same filenames.
        - Easy to wipe (`rm -rf /tmp/<project>`) without touching other scratch.
        - Lets permission rules be scoped narrowly (`Read(/tmp/<project>/**)`,
          `Write(/tmp/<project>/**)`) instead of granting `/tmp/**` blanket
          access.

        The grant model follows from this: the `/tmp/<project>/` subdirectory
        gets full `Read` + `Write` + `Edit` access (the recursive
        `/tmp/<project>/**` form — see the `Read(~/.config)` note: a bare
        directory path does not cover its contents), while `/tmp` itself is
        **not** granted. Never request or rely on a blanket `Read(/tmp/**)` /
        `Write(/tmp/**)`; scope every tmp permission to the project subdir.

        # GitHub: MCP server, not the `gh` CLI

        GitHub work goes through the **GitHub MCP server**
        (`mcp__plugin_claude-code-home-manager_github__*`) whenever the server
        exposes the operation — pull requests, issues, releases, commits, tags,
        branches, file contents, and code/repo/user search. Reach for it before
        shelling out to `gh` or fetching github.com with WebFetch. This narrows
        the `gh` exception listed under the jj rules above.

        Why: the MCP tools return structured JSON that needs no parsing, accept
        `minimal_output` and pagination to keep context small, and authenticate
        from the sops-managed `claude-code/github-mcp` token rather than
        whatever `gh` auth state the shell happens to carry.

        Fall back to `gh` only for what the MCP server does not expose — Actions
        logs (`gh run view`, `gh run list`), `gh pr checks` — and to WebFetch
        only for non-API pages.

        Read-only MCP tools (`get_*`, `list_*`, `search_*`, `issue_read`,
        `pull_request_read`) are allowed in the harness and run without
        prompting. Every other GitHub MCP tool mutates a remote repository —
        `merge_pull_request`, `delete_file`, `push_files`, `create_*`,
        `*_write`, the comment tools — and will prompt. Confirm those with the
        user instead of assuming approval.
      '';

      lspServers = {
        svelte = {
          command = "${pkgs.svelte-language-server}/bin/svelteserver";
          args = [ "--stdio" ];
          extensionToLanguage.".svelte" = "svelte";
        };
      };

      settings = {
        enabledPlugins = {
          "feature-dev@claude-plugins-official" = true;
        };

        # Auto-mode classifier context for every repo on this machine. Only
        # ~/.claude/settings.json is read for this — the classifier ignores
        # `autoMode` in project settings on purpose, so a checked-out repo
        # cannot widen its own trust boundary.
        autoMode = import ./claude-auto-mode.nix;

        permissions = {
          allow = [
            "Read(//nix/store/**)"
            # GitHub — read-only only. Every mutating tool (merge_pull_request,
            # delete_file, push_files, create_*, *_write, …) avoids these
            # prefixes, so it keeps prompting like `gh` and jj's write ops do.
            "mcp__plugin_claude-code-home-manager_github__get_*"
            "mcp__plugin_claude-code-home-manager_github__list_*"
            "mcp__plugin_claude-code-home-manager_github__search_*"
            "mcp__plugin_claude-code-home-manager_github__issue_read"
            "mcp__plugin_claude-code-home-manager_github__pull_request_read"
            "mcp__plugin_claude-code-home-manager_context7__*"
            "mcp__claude-design__get_*"
            "mcp__claude-design__list_*"
            "mcp__claude-design__read_*"
            "mcp__claude-design__render_*"
            "Bash(nix eval *)"
            "Bash(nix search *)"
            "Bash(nix --version)"
            "Bash(tee /tmp/*)"
            "Bash(jj st*)"
            "Bash(jj status*)"
            "Bash(jj log*)"
            "Bash(jj diff*)"
            "Bash(jj show*)"
            "Bash(jj evolog*)"
            "Bash(jj op log*)"
            "Bash(jj op show*)"
            "Bash(jj files*)"
            "Bash(jj cat*)"
            "Bash(jj file annotate*)"
            "Bash(jj file show*)"
            "Bash(jj file list*)"
            "Bash(jj bookmark list*)"
            "Bash(jj git remote list*)"
            "Bash(jj config get*)"
            "Bash(jj config list*)"
            "Bash(jj root*)"
            "Bash(jj help*)"
            "Bash(jj --version)"
            "Bash(jj version)"
            # Duplicated for --no-pager because the jj skill prefers that form.
            "Bash(jj --no-pager st*)"
            "Bash(jj --no-pager status*)"
            "Bash(jj --no-pager log*)"
            "Bash(jj --no-pager diff*)"
            "Bash(jj --no-pager show*)"
            "Bash(jj --no-pager evolog*)"
            "Bash(jj --no-pager op log*)"
            "Bash(jj --no-pager op show*)"
            "Bash(jj --no-pager files*)"
            "Bash(jj --no-pager cat*)"
            "Bash(jj --no-pager file annotate*)"
            "Bash(jj --no-pager file show*)"
            "Bash(jj --no-pager file list*)"
            "Bash(jj --no-pager bookmark list*)"
            "Bash(jj git fetch*)"

            # Everything below is hoisted out of per-project settings.local.json
            # so it applies to every project and stops re-prompting.
            # Content-reading shells (cat/grep/find/head/tail/env) are
            # deliberately NOT hoisted: Bash bypasses the Read() deny rules that
            # protect .env/secrets, so those stay per-project.
            "WebSearch"
            "WebFetch(domain:github.com)"
            "WebFetch(domain:raw.githubusercontent.com)"
            "WebFetch(domain:gist.github.com)"
            "WebFetch(domain:wiki.nixos.org)"
            "WebFetch(domain:search.nixos.org)"
            # `nix build` only realizes to the store, so it is safe unattended.
            "Bash(nix run *)"
            "Bash(nix build *)"
            "Bash(nix store *)"
            "Bash(nix log *)"
            "Bash(nix hash *)"
            "Bash(nix flake *)"
            "Bash(nix-prefetch-url *)"
            "Bash(nix-instantiate --eval *)"
            # jj does not replace gh, so read-only gh stays allowed.
            "Bash(gh pr view *)"
            "Bash(gh pr list *)"
            "Bash(gh pr diff *)"
            "Bash(gh pr checks *)"
            "Bash(gh run view *)"
            "Bash(gh run list *)"
            "Bash(gh api repos/*)"
            "Bash(gh search *)"
            # Plumbing with no jj equivalent; read-only and non-secret.
            "Bash(git ls-remote *)"
            "Bash(git symbolic-ref *)"
            "Bash(git rev-list *)"
            "Bash(git check-ignore *)"
            # Filesystem inspection — metadata/lookup only, never file contents.
            # (cat/grep/head/tail are NOT here: Bash reading file contents would
            # bypass the Read() deny rules protecting .env/secrets.)
            "Bash(ls *)"
            "Bash(stat *)"
            "Bash(command -v *)"
            # obsidian-wiki. The checkout is upstream-managed (`jj git fetch`
            # upgrades it), so it stays read-only; notes go into the vault.
            # `Edit()` is the only editing verb file checks match — a
            # `Write()`/`NotebookEdit()` rule parses but never matches and warns
            # at startup (2.1.210+), so Edit covers every write to the vault.
            "Read(~/.obsidian-wiki/**)"
            "Read(~/Documents/obsidian-wiki-vault/**)"
            "Edit(~/Documents/obsidian-wiki-vault/**)"
          ];
          # Split by recoverability, not by verb. `deny` is for operations that
          # destroy work with no way back — Claude cannot run these at all, in
          # any permission mode, and hands them over for the user to invoke.
          # `ask` is for operations that reach the remote or the colocated git
          # repo but stay recoverable; those prompt instead of blocking.
          #
          # Precedence is deny > ask > allow, first match wins, and specificity
          # does not reorder it: `jj git fetch` is absent from both lists
          # because a rule here would override the allow above and it is the
          # sanctioned way to pull. Both lists survive auto mode — the
          # classifier never sees a call these match — which a conversational
          # "don't push" does not, since compaction can drop it from context.
          #
          # Matching is literal-prefix with no argument normalization, so
          # `jj --no-pager abandon` and `git -C dir push` match neither list and
          # fall through to a normal prompt. This is a guardrail, not a sandbox.
          deny = [
            "Bash(jj abandon*)"
            "Bash(jj op abandon*)"
            "Bash(jj op restore*)"
            "Bash(jj util gc*)"
            "Bash(jj workspace forget*)"

            # git has no operation log to fall back on, so the same verb has a
            # wider blast radius here. `git submodule` and `git lfs` stay absent
            # — they are the documented exceptions where jj has no equivalent.
            "Bash(git branch -D *)"
            "Bash(git branch -d *)"
            "Bash(git checkout*)"
            "Bash(git clean*)"
            "Bash(git filter-branch*)"
            "Bash(git gc*)"
            "Bash(git prune*)"
            "Bash(git reflog delete*)"
            "Bash(git reflog expire*)"
            "Bash(git repack*)"
            "Bash(git reset --hard*)"
            "Bash(git restore*)"
            "Bash(git stash clear*)"
            "Bash(git stash drop*)"
            "Bash(git worktree prune*)"
            "Bash(git worktree remove*)"
          ];

          ask = [
            "Bash(jj bookmark delete*)"
            "Bash(jj bookmark forget*)"
            "Bash(jj bookmark untrack*)"
            "Bash(jj git export*)"
            "Bash(jj git import*)"
            "Bash(jj git push*)"
            "Bash(jj git remote add*)"
            "Bash(jj git remote remove*)"
            "Bash(jj git remote rename*)"
            "Bash(jj git remote set-url*)"
            "Bash(jj op undo*)"
            "Bash(jj undo*)"

            "Bash(git fetch*)"
            "Bash(git pull*)"
            "Bash(git push*)"
            "Bash(git remote add*)"
            "Bash(git remote remove*)"
            "Bash(git remote rename*)"
            "Bash(git remote set-url*)"
            "Bash(git rm*)"
            "Bash(git tag -d *)"
            "Bash(git update-ref*)"
          ];

          # Both live outside whatever project Claude was launched from, so the
          # allow rules above are inert until the paths are part of the workspace.
          additionalDirectories = [
            "${config.home.homeDirectory}/.obsidian-wiki"
            "${config.home.homeDirectory}/Documents/obsidian-wiki-vault"
          ];
        };

        # obsidian-wiki auto-capture. The upstream script lives in the checkout
        # (so `jj git fetch` upgrades it) but needs python3, which is not in the
        # global profile — this wrapper supplies it.
        hooks.Stop = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = lib.getExe (
                  pkgs.writeShellApplication {
                    name = "wiki-stop-capture";
                    runtimeInputs = [
                      pkgs.bash
                      pkgs.python3
                      pkgs.coreutils
                      pkgs.gawk
                    ];
                    text = ''
                      exec bash ${config.home.homeDirectory}/.obsidian-wiki/repo/.claude/hooks/wiki-stop-capture.sh
                    '';
                  }
                );
              }
            ];
          }
        ];
      };
    };

    ssh = {
      enable = true;
      settings =
        let
          keyNamePrefix = "id_ed25519";
        in
        {
          "github.com" = {
            HostName = "github.com";
            User = "git";
            IdentityFile = "~/.ssh/${keyNamePrefix}_git";
            IdentitiesOnly = true;
          };
          "gitlab.com" = {
            HostName = "gitlab.com";
            User = "git";
            IdentityFile = "~/.ssh/${keyNamePrefix}_git";
            IdentitiesOnly = true;
          };
          "valinor" = {
            HostName = "valinor";
            User = "datahearth";
            IdentityFile = "~/.ssh/${keyNamePrefix}";
            IdentitiesOnly = true;
          };
        };
    };

    zsh = {
      enable = true;
      extraPlugins = [
        {
          name = "zsh-completion-sync";
          src = pkgs.zsh-completion-sync;
          file = "share/zsh-completion-sync/zsh-completion-sync.plugin.zsh";
        }
      ];
      extraAliases = {
        open = "xdg-open";
      };
      envExtra =
        lib.optionalString config.home_modules.direnv.enable ''
          if [[ -n "$CLAUDECODE" ]]; then
            eval "$(${config.programs.direnv.package}/bin/direnv hook zsh)"
          fi
        ''
        + lib.optionalString config.home_modules.claude-code.enable ''
          if [[ -r /run/secrets/claude-code/github-mcp ]]; then
            export GITHUB_TOKEN="$(${pkgs.coreutils}/bin/cat /run/secrets/claude-code/github-mcp)"
          fi
          if [[ -r /run/secrets/claude-code/context7-mcp ]]; then
            export CONTEXT7_API_KEY="$(${pkgs.coreutils}/bin/cat /run/secrets/claude-code/context7-mcp)"
          fi
        '';
    };

    neovim = {
      enable = true;
      defaultEditor = true;
    };

    git = {
      enable = true;
      signingKey = "dev@antoine-langlois.net";
      difftastic.enable = true;
    };

    jujutsu = {
      enable = true;
      signingKey = "dev@antoine-langlois.net";
    };

    starship = {
      enable = true;
      gitModules = "conditional";
    };

    hyprland = {
      enable = true;
      display_manager = true;
      status_bar = "waybar";
      window_rules = [
        {
          workspace = 1;
          match.class = "Alacritty";
        }
        {
          workspace = 2;
          match = {
            class = "zen-beta";
            initial_title = "Zen Browser";
          };
        }
        {
          workspace = 3;
          match.class = "dev.zed.Zed";
        }
        {
          workspace = 3;
          match = {
            class = "code";
            initial_title = "Visual Studio Code";
          };
        }
        {
          workspace = 3;
          # The app reports itself as "com.anthropic.Claude", not "claude-desktop".
          match.class = "com\\.anthropic\\.Claude";
        }
        {
          workspace = 4;
          match.class = "discord";
        }
        {
          workspace = 4;
          match.class = "signal";
        }
        {
          workspace = 6;
          match.class = "[Ss]potify"; # XWayland "Spotify" + native-Wayland "spotify"
        }
        {
          workspace = 7;
          match.class = "thunderbird";
        }
        {
          workspace = 9;
          match.class = "F5 VPN";
        }
      ];
      exec_once = [
        # Commands that need arguments stay as raw strings.
        "signal-desktop --start-in-tray"
        "discord --start-minimized"
      ]
      # Bare program launches: resolve each package to its main executable.
      ++ map lib.getExe [
        config.programs.zen-browser.package
        pkgs.spotify
        pkgs.thunderbird
        pkgs.protonmail-bridge-gui
        pkgs.claude-desktop
      ]
      # opencloud-desktop sets no meta.mainProgram and ships two binaries
      # (GUI `opencloud`, CLI `opencloudcmd`); the GUI launches to tray by default.
      ++ [ (lib.getExe' pkgs.opencloud-desktop "opencloud") ];

      awww.randomize = {
        enable = true;
        directory = "${config.home.homeDirectory}/Documents/OpenCloud/Personal/medias/wallpapers";
      };
    };
  };
}
