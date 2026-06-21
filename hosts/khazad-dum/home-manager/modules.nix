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
      plugins = [
        (pkgs.fetchFromGitHub {
          owner = "DietrichGebert";
          repo = "ponytail";
          rev = "v4.7.0";
          hash = "sha256-Q6vlkbTfBFrNFTxEwYeMe5ciOe6QdULegvExwT//gJs=";
        })
      ];

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
      };

      lspServers = {
        svelte = {
          command = "${pkgs.svelte-language-server}/bin/svelteserver";
          args = [ "--stdio" ];
          extensionToLanguage.".svelte" = "svelte";
        };
      };

      settings = {
        effortLevel = "xhigh";
        enabledPlugins = {
          "feature-dev@claude-plugins-official" = true;
        };
        permissions.allow = [
          "Read(//nix/store/**)"
          # MCP
          "mcp__plugin_claude-code-home-manager_github__*"
          "mcp__plugin_claude-code-home-manager_context7__*"
          # Nix
          "Bash(nix eval *)"
          "Bash(nix search *)"
          "Bash(nix --version)"
          # Logging
          "Bash(tee /tmp/*)"
          # jj — read-only inspection
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
          "Bash(jj split --help)"
          # jj --no-pager — read-only inspection (skill prefers this form)
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
          # jj — remote read
          "Bash(jj git fetch*)"

          # ── Universal grants ──────────────────────────────────────────────
          # Hoisted out of per-project settings.local.json so they apply to
          # every project and stop re-prompting. Content-reading shells
          # (cat/grep/find/head/tail/env) are deliberately NOT hoisted: Bash
          # bypasses the Read() deny rules that protect .env/secrets, so those
          # stay per-project.
          # Web
          "WebSearch"
          "WebFetch(domain:github.com)"
          "WebFetch(domain:raw.githubusercontent.com)"
          "WebFetch(domain:gist.github.com)"
          "WebFetch(domain:wiki.nixos.org)"
          "WebFetch(domain:search.nixos.org)"
          # Nix — build/eval/query (build only realizes to the store)
          "Bash(nix run *)"
          "Bash(nix build *)"
          "Bash(nix store *)"
          "Bash(nix log *)"
          "Bash(nix hash *)"
          "Bash(nix flake *)"
          "Bash(nix-prefetch-url *)"
          "Bash(nix-instantiate --eval *)"
          # gh — read-only PR/run inspection (jj does not replace gh)
          "Bash(gh pr view *)"
          "Bash(gh pr list *)"
          "Bash(gh pr diff *)"
          "Bash(gh pr checks *)"
          "Bash(gh run view *)"
          "Bash(gh run list *)"
          "Bash(gh api repos/*)"
          "Bash(gh search *)"
          # git plumbing — no jj equivalent, read-only, non-secret
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
          match.class = "thunderbird";
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
      ];

      awww.randomize = {
        enable = true;
        directory = "/run/media/datahearth/proton/medias/wallpapers";
      };
    };
  };
}
