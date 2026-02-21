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

    marketplaces = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = "Extra plugin marketplaces (extraKnownMarketplaces in settings.json)";
      example = lib.literalExpression ''
        {
          superpowers-marketplace = {
            source = {
              source = "github";
              repo = "obra/superpowers-marketplace";
            };
          };
        }
      '';
    };

    plugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = { };
      description = "Plugins to enable/disable (enabledPlugins in settings.json)";
      example = lib.literalExpression ''
        {
          "superpowers@superpowers-marketplace" = true;
          "typescript-lsp@claude-plugins-official" = true;
        }
      '';
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = "MCP (Model Context Protocol) servers configuration";
    };

    memory = {
      text = lib.mkOption {
        type = lib.types.nullOr lib.types.lines;
        default = null;
        description = "Inline memory content for CLAUDE.md";
      };

      source = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a file containing memory content for CLAUDE.md";
      };
    };

    rules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = "Modular rule files for Claude Code, stored in .claude/rules/";
    };

    rulesDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a directory containing rule files";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;
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
      // lib.optionalAttrs (cfg.marketplaces != { }) {
        extraKnownMarketplaces = cfg.marketplaces;
      }
      // lib.optionalAttrs (cfg.plugins != { }) {
        enabledPlugins = cfg.plugins;
      }
      // cfg.settings;
      inherit (cfg)
        mcpServers
        memory
        rules
        rulesDir
        ;
    };
  };
}
