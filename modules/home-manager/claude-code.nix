{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.claude-code;
  jsonFormat = pkgs.formats.json { };

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

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages to make available in Claude Code's PATH";
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
      settings = {
        attribution = {
          commit = "";
          pr = "";
        };
        permissions.deny = [
          "Read(./.env)"
          "Read(./.env.*)"
          "Read(./secrets/**)"
          "Read(./**/credentials*)"
        ];
        cleanupPeriodDays = 7;
        statusLine = {
          type = "command";
          command = toString statuslineScript;
        };
      }
      // cfg.settings;
      inherit (cfg) context mcpServers;
    };
  };
}
