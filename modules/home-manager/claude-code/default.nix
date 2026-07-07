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

  statuslineScript = pkgs.writeShellScript "claude-statusline" ''
    input=$(cat)

    cwd=$(echo "$input" | ${lib.getExe pkgs.jq} -r '.workspace.current_dir')
    model=$(echo "$input" | ${lib.getExe pkgs.jq} -r '.model.display_name')

    if [ "$cwd" = "$HOME" ]; then
      dir="~"
    elif [ "$cwd" = "/" ]; then
      dir="/"
    else
      dir=$(basename "$cwd")
    fi

    output=$(printf "\033[36m%s\033[0m" "$dir")

    if ${lib.getExe pkgs.git} -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
      branch=$(${lib.getExe pkgs.git} -C "$cwd" branch --show-current 2>/dev/null || echo "detached")
      output="$output $(printf "\033[35m%s\033[0m" "$branch")"
    fi

    output="$output $(printf "\033[34m[%s]\033[0m" "$model")"

    echo "$output"
  '';

  # PreToolUse guard: steer bare dev-tool invocations (python3/node/cargo/…)
  # toward the project's devShell or `nix run`/`nix shell` on this NixOS box.
  nixRunGuard = pkgs.writeShellApplication {
    name = "claude-nix-run-guard";
    runtimeInputs = [
      pkgs.jq
      pkgs.gnused
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
    SessionStart = [ { hooks = [ { type = "command"; command = lib.getExe loadDirenv; } ]; } ];
    CwdChanged = [ { hooks = [ { type = "command"; command = lib.getExe loadDirenv; } ]; } ];
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
      type = lib.types.listOf (lib.types.either lib.types.package lib.types.path);
      default = [ ];
      description = ''
        Plugins to load via `--plugin-dir`. Each entry is a plugin directory,
        either a local path or a fetcher output (e.g. `pkgs.fetchFromGitHub`).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;
      package = lib.mkIf (cfg.extraPackages != [ ]) (
        pkgs.symlinkJoin {
          name = "claude-code-with-deps";
          paths = [ pkgs.claude-code ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/claude \
              --prefix PATH : ${lib.makeBinPath cfg.extraPackages}
          '';
          inherit (pkgs.claude-code) meta;
        }
      );
      settings = lib.recursiveUpdate {
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
            # Destructive jj ops — paired with the broad `Bash(jj *)` allow in host configs.
            "Bash(jj git push*)"
            "Bash(jj op abandon*)"
            "Bash(jj workspace forget*)"
          ];
        };
        cleanupPeriodDays = 7;
        statusLine = {
          type = "command";
          command = toString statuslineScript;
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
      } cfg.settings;
      context = composedContext;
      skills.jj = ./skills/jj;
      inherit (cfg) mcpServers lspServers plugins;
    };
  };
}
