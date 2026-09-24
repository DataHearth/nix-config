{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.claude-code;
  jsonFormat = pkgs.formats.json { };

  globalContext = builtins.readFile ./context.md;
  userContext = if builtins.isPath cfg.context then builtins.readFile cfg.context else cfg.context;
  composedContext = globalContext + lib.optionalString (userContext != "") ("\n" + userContext);

  statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [
      pkgs.jq
      pkgs.jujutsu
      pkgs.git
      pkgs.coreutils
    ];
    bashOptions = [
      "nounset"
      "pipefail"
    ];
    text = builtins.readFile ./statusline.sh;
  };

  # PreToolUse guard: steer bare dev-tool invocations (python3/node/cargo/…)
  # toward the project's devShell or `nix run`/`nix shell` on this NixOS box.
  nixRunGuard = pkgs.writeShellApplication {
    name = "claude-nix-run-guard";
    runtimeInputs = [
      pkgs.jq
      pkgs.gnused
      pkgs.gawk
      pkgs.coreutils
    ];
    bashOptions = [
      "nounset"
      "pipefail"
    ];
    text = builtins.readFile ./nix-run-guard.sh;
  };

  # PreToolUse guard: reject a leading `cd` into the directory Claude is
  # already in, since it habitually prepends a redundant `cd <project> &&`.
  cdGuard = pkgs.writeShellApplication {
    name = "claude-cd-guard";
    runtimeInputs = [
      pkgs.jq
      pkgs.gnused
      pkgs.coreutils
    ];
    bashOptions = [
      "nounset"
      "pipefail"
    ];
    text = builtins.readFile ./cd-guard.sh;
  };

  # SessionStart + CwdChanged hook: load the cwd's direnv/nix-direnv devShell
  # into Claude Code's Bash environment. Chiefly for the Claude Desktop "Code"
  # tab, which launches from the GUI and inherits no project devShell (see
  # ./load-direnv.sh). Fully self-contained — bakes direnv/nix/bash so it works
  # regardless of the PATH the graphical session hands the app.
  loadDirenv = pkgs.writeShellApplication {
    name = "claude-load-direnv";
    runtimeInputs = [
      pkgs.direnv
      pkgs.nix
      pkgs.bash
      pkgs.jq
      pkgs.gnugrep
      pkgs.coreutils
    ];
    bashOptions = [
      "nounset"
      "pipefail"
    ];
    text = builtins.readFile ./load-direnv.sh;
  };

  # Only wire the devShell loader when direnv is actually configured.
  devShellHooks = lib.optionalAttrs config.home_modules.direnv.enable {
    SessionStart = [
      {
        hooks = [
          {
            type = "command";
            command = lib.getExe loadDirenv;
          }
        ];
      }
    ];
    CwdChanged = [
      {
        hooks = [
          {
            type = "command";
            command = lib.getExe loadDirenv;
          }
        ];
      }
    ];
  };
in
{
  options.home_modules.claude-code = {
    enable = lib.mkEnableOption "Claude Code, Anthropic's official CLI";

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = "Extra JSON configuration merged into Claude Code settings.json";
    };

    context = lib.mkOption {
      type = lib.types.either lib.types.lines lib.types.path;
      default = "";
      description = "Global context for Claude Code, written to ~/.claude/CLAUDE.md";
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = "MCP (Model Context Protocol) servers configuration";
    };

    lspServers = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = ''
        LSP (Language Server Protocol) servers exposed to Claude Code. Each
        entry is bundled into an auto-loaded plugin (the same mechanism the
        official `gopls`/`pyright` LSP plugins use), giving Claude live
        diagnostics, go-to-definition and references. `command` should be an
        absolute store path so the binary need not be on PATH.
      '';
      example = {
        svelte = {
          command = "/nix/store/.../bin/svelteserver";
          args = [ "--stdio" ];
          extensionToLanguage.".svelte" = "svelte";
        };
      };
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages to make available in Claude Code's PATH";
    };

    plugins = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.package lib.types.path);
      default = { };
      description = ''
        Plugins to load. The attribute name becomes the plugin directory name;
        the value is a plugin directory, either a local path or a fetcher
        output (e.g. `pkgs.fetchFromGitHub`).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;
      package = pkgs.symlinkJoin {
        name = "claude-code-with-deps";
        paths = [ pkgs.claude-code ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        # Launched from a shell where direnv already loaded a project, claude
        # inherits that devShell's DIRENV_DIFF. The first `cd` out of the
        # project in a Bash call makes the shell's direnv hook restore the
        # pre-load environment recorded there, which predates every PATH
        # prefix added below and inside pkgs.claude-code — python3, rg,
        # bubblewrap and socat then vanish mid-session. Dropping only direnv's
        # bookkeeping leaves nothing to restore while keeping the devShell's
        # variables: fully unloading it instead strips NODE_EXTRA_CA_CERTS,
        # which node reads once at startup, so HTTP MCPs behind a corporate
        # CA fail TLS and no SessionStart hook can put it back.
        postBuild = ''
          wrapProgram $out/bin/claude \
            --unset DIRENV_DIR \
            --unset DIRENV_FILE \
            --unset DIRENV_DIFF \
            --unset DIRENV_WATCHES \
            ${lib.optionalString (cfg.extraPackages != [ ]) "--prefix PATH : ${lib.makeBinPath cfg.extraPackages}"}
        '';
        inherit (pkgs.claude-code) meta version;
      };
      settings =
        let
          defaults = {
            attribution = {
              commit = "";
              pr = "";
            };
            permissions = {
              allow = [
                "Read(./env.example)"
              ];
              deny = [
                "Read(./.env)"
                "Read(./.env.*)"
                "Read(./secrets/**)"
                "Read(./**/credentials*)"
              ];
            };
            cleanupPeriodDays = 7;
            disableAgentView = true;
            remoteControlAtStartup = false;
            statusLine = {
              type = "command";
              command = lib.getExe statusline;
              hideVimModeIndicator = true;
            };
            hooks = {
              PreToolUse = [
                {
                  matcher = "Bash";
                  hooks = [
                    {
                      type = "command";
                      command = lib.getExe nixRunGuard;
                    }
                    {
                      type = "command";
                      command = lib.getExe cdGuard;
                    }
                  ];
                }
              ];
            }
            // devShellHooks;
          };
          merged = lib.recursiveUpdate defaults cfg.settings;
          userPermissions = cfg.settings.permissions or { };
        in
        merged
        // {
          # recursiveUpdate replaces lists outright, so a host that sets any
          # permission rule of its own would silently drop the secret-protecting
          # denies above. Concatenate instead.
          permissions = merged.permissions // {
            allow = defaults.permissions.allow ++ (userPermissions.allow or [ ]);
            deny = defaults.permissions.deny ++ (userPermissions.deny or [ ]);
          };
        };
      context = composedContext;
      skills.jj = ./skills/jj;
      inherit (cfg) mcpServers lspServers plugins;
    };
  };
}
