{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zen-browser = {
    enable = true;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFormHistory = true;
      PasswordManagerEnabled = false;
      OfferToSaveLogins = false;
      OfferToSaveLoginsDefault = false;
      FirefoxSuggest = {
        WebSuggestions = false;
        SponsoredSuggestions = false;
        ImproveSuggest = false;
      };
      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      ExtensionSettings =
        let
          ext = id: url: {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/${url}/latest.xpi";
            installation_mode = "force_installed";
          };
          extDisabled = id: url: {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/${url}/latest.xpi";
            installation_mode = "normal_installed";
          };
        in
        {
          "uBlock0@raymondhill.net" = ext "uBlock0@raymondhill.net" "ublock-origin";
          "jid1-MnnxcxisBPnSXQ@jetpack" = ext "jid1-MnnxcxisBPnSXQ@jetpack" "privacy-badger17";
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" =
            ext "{446900e4-71c2-419f-a6a7-df9c091e268b}" "bitwarden-password-manager";
          "addon@darkreader.org" = ext "addon@darkreader.org" "darkreader";
          "{cf3dba12-a848-4f68-8e2d-f9fadc0721de}" =
            ext "{cf3dba12-a848-4f68-8e2d-f9fadc0721de}" "google-lighthouse";
          "78272b6fa58f4a1abaac99321d503a20@proton.me" =
            extDisabled "78272b6fa58f4a1abaac99321d503a20@proton.me" "proton-pass";
          "vpn@proton.ch" = ext "vpn@proton.ch" "proton-vpn-firefox-extension";
          "sponsorBlocker@ajay.app" = ext "sponsorBlocker@ajay.app" "sponsorblock";
          "fr-dicollecte@dictionaries.addons.mozilla.org" =
            ext "fr-dicollecte@dictionaries.addons.mozilla.org" "dictionnaire-fran%C3%A7ais1";
          "ef-french-simplified-orthograph@dictionaries.addons.mozilla.org" =
            ext "ef-french-simplified-orthograph@dictionaries.addons.mozilla.org" "corecteur-ortografe-simplifiee";
          "langpack-fr@firefox.mozilla.org" = ext "langpack-fr@firefox.mozilla.org" "francais-language-pack";
        };
    };

    profiles.default = {
      id = 0;
      isDefault = true;
      path = "gz71a4fv.Default Profile";

      mods = [
        "ad97bb70-0066-4e42-9b5f-173a5e42c6fc" # SuperPins
      ];

      search = {
        default = "qwant";
        force = true;
        engines = {
          "qwant" = {
            urls = [ { template = "https://www.qwant.com/?q={searchTerms}"; } ];
            icon = "https://www.qwant.com/favicon.ico";
            definedAliases = [ "@q" ];
          };
          "google".metaData.hidden = true;
          "bing".metaData.hidden = true;
        };
      };

      settings = {
        # Startup: restore session
        "browser.startup.page" = 3;
        "browser.shell.checkDefaultBrowser" = true;

        # Spellcheck
        "layout.spellcheckDefault" = 1;
        "spellchecker.dictionary" = "fr,en-US";

        # Search suggestions
        "browser.search.suggest.enabled" = true;
        "browser.urlbar.suggest.searches" = true;

        # Sidebar + topbar layout
        "zen.view.use-single-toolbar" = false;

        # Fractional scaling breaks extension popups on wlroots compositors
        # (bugzilla#1849109). Disable until upstream fix lands.
        "widget.wayland.fractional-scale.enabled" = false;

        # Disable all saving/autofill
        "signon.rememberSignons" = false;
        "signon.autofillForms" = false;
        "browser.formfill.enable" = false;
        "extensions.formautofill.addresses.enabled" = false;
        "extensions.formautofill.creditCards.enabled" = false;

        # Telemetry
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "browser.ping-centre.telemetry" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
      };

      containers = { };
    };
  };

  home_modules = {
    alacritty.enable = true;
    atuin.enable = true;
    bat.enable = true;
    direnv.enable = true;
    theme.enable = true;
    vscode.enable = true;
    yazi.enable = true;
    zed-editor.enable = true;
    zellij.enable = true;
    claude-code = {
      enable = true;

      context = ''
        ## Tool Usage
        - Always prefer native Claude Code tools (Glob, Grep, Read, Edit, Write) over system binaries (find, grep, cat, sed, awk).
        - Only fall back to Bash system binaries when you need capabilities not available in native tools (e.g., file permissions, timestamps, exec).

        ## Bash Tool
        - Never use `2>&1`, `2>/dev/null`, or other stderr redirections — the Bash tool captures both stdout and stderr by default.
        - If a command produces verbose output that may be truncated, use `tee /tmp/<descriptive-name>.log` to preserve the full output for later reading.
      '';

      extraPackages = with pkgs; [
        # required for claude-mem
        bun
        nodejs-slim
        python313
        # uvx wrapper: inject native libs so uv-installed wheels (numpy, chromadb) find libstdc++/libz
        # and force uv to use system Python instead of its own dynamically-linked managed copy
        (symlinkJoin {
          name = "uv-fhs";
          paths = [ uv ];
          nativeBuildInputs = [ makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/uvx \
              --prefix LD_LIBRARY_PATH : "${
                lib.makeLibraryPath [
                  stdenv.cc.cc.lib
                  zlib
                ]
              }" \
              --set UV_PYTHON_PREFERENCE only-system
          '';
        })

        # required by caveman
        nodejs-slim
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

      settings = {
        enabledPlugins = {
          "feature-dev@claude-plugins-official" = true;
          "claude-md-management@claude-plugins-official" = true;
          "claude-code-setup@claude-plugins-official" = true;
          "claude-mem@thedotmack" = true;
          "caveman@caveman" = true;
          "andrej-karpathy-skills@karpathy-skills" = true;
        };
        extraKnownMarketplaces = {
          "thedotmack/claude-mem" = {
            source = {
              source = "github";
              repo = "thedotmack/claude-mem";
            };
          };
          "JuliusBrussee/caveman" = {
            source = {
              source = "github";
              repo = "JuliusBrussee/caveman";
            };
          };
          "forrestchang/andrej-karpathy-skills" = {
            source = {
              source = "github";
              repo = "forrestchang/andrej-karpathy-skills";
            };
          };
        };
        permissions.allow = [
          "Read(//nix/store)"
          # MCP
          "mcp__plugin_claude-code-home-manager_github__*"
          "mcp__plugin_claude-code-home-manager_context7__*"
          "mcp__plugin_claude-mem_mcp-search__*"
          # Nix
          "Bash(nix eval *)"
          "Bash(nix search *)"
          "Bash(nix flake show *)"
          "Bash(nix --version)"
          # Logging
          "Bash(tee /tmp/*)"
        ];
      };
    };

    ssh = {
      enable = true;
      matchBlocks =
        let
          keyNamePrefix = "id_ed25519";
        in
        {
          "github.com" = {
            hostname = "github.com";
            user = "git";
            identityFile = "~/.ssh/${keyNamePrefix}_git";
            identitiesOnly = true;
          };
          "gitlab.com" = {
            hostname = "gitlab.com";
            user = "git";
            identityFile = "~/.ssh/${keyNamePrefix}_git";
            identitiesOnly = true;
          };
          "valinor" = {
            hostname = "valinor";
            user = "datahearth";
            identityFile = "~/.ssh/${keyNamePrefix}";
            identitiesOnly = true;
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
        "workspace 1, match:class Alacritty"
        "workspace 2, match:class zen-beta, match:initial_title Zen Browser"
        "workspace 3, match:class dev.zed.Zed"
        "workspace 3, match:class code, match:initial_title Visual Studio Code"
        "workspace 4, match:class discord"
        "workspace 4, match:class signal"
        "workspace 9, match:class F5 VPN"
      ];
      exec_once = [
        "signal-desktop --start-in-tray"
        "discord --start-minimized"
        "zen-beta"
      ];

      awww.randomize = {
        enable = true;
        directory = "/run/media/datahearth/proton/medias/wallpapers";
      };
    };
  };
}
