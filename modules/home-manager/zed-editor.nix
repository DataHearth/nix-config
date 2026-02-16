{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.zed-editor;

in
{
  options.home_modules.zed-editor = {
    enable = lib.mkEnableOption "zed-editor";
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      mutableUserSettings = false;
      mutableUserTasks = false;
      mutableUserDebug = false;

      # LSPs, formatters, and tools available in Zed's environment
      extraPackages = with pkgs; [
        # Nix
        nixd
        nixfmt

        # Rust
        rust-analyzer

        # Go
        gopls
        golangci-lint

        # Python
        ruff
        pyright

        # TypeScript/JavaScript
        typescript-language-server
        vtsls
        eslint_d

        # Web
        svelte-language-server
        tailwindcss-language-server
        htmx-lsp

        # YAML/JSON/TOML
        yaml-language-server
        vscode-langservers-extracted
        taplo

        # Shell
        bash-language-server
        shfmt
        shellcheck

        # Lua
        lua-language-server
        stylua

        # Markdown
        marksman

        # SQL
        sqlfluff
      ];

      # Extensions from Zed's extension registry
      extensions = [
        # Languages
        "nix"
        "toml"
        "rust"
        "ruff"
        "dockerfile"
        "svelte"
        "tailwindcss"
        "sql"
        "lua"
        "xml"
        "csv"
        "zig"
        "proto"
        "rainbow-csv"
        "helm"

        # Version control
        "git-firefly"
      ];

      userSettings = {
        vim_mode = true;
        base_keymap = "VSCode";

        project_panel = {
          hide_root = true;
        };

        diagnostics = {
          inline.enabled= true;
        };

        # Disable telemetry and AI
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        show_edit_predictions = false;

        # Appearance
        ui_font_size = 16;
        buffer_font_size = 15;
        buffer_font_family = "Mononoki Nerd Font";
        tab_size = 2;
        show_wrap_guides = true;
        wrap_guides = [ 120 ];
        indent_guides.enabled = true;

        # Behavior
        autosave.after_delay.milliseconds = 1000;
        format_on_save = "on";
        linked_edits = true;
        prettier.allowed = false;

        # Exclusions
        file_scan_exclusions = [
          "**/.git"
          "**/node_modules"
          "**/target"
          "**/.direnv"
          "**/result"
        ];

        # Git
        git = {
          inline_blame = {
            enabled = true;
            show_commit_summary = true;
          };
        };

        # File types
        file_types = {
          markdown = [ "*.mdx" ];
          plaintext = [ "LICENSE" ];
        };

        # Agent
        agent = {
          show_turn_stats = true;
        };
        agent_servers.claude.env = {
          CLAUDE_CODE_EXECUTABLE = "${pkgs.claude-code}/bin/claude";
        };

        # Language-specific settings
        languages = {
          Nix = {
            language_servers = [
              "nixd"
              "!nil"
            ];
          };
          Go = {
            formatter = "language_server";
            language_servers = [ "gopls" ];
          };
          YAML = {
            formatter = "language_server";
            language_servers = [ "yaml-language-server" ];
          };
          JSON = {
            language_servers = [ "json-language-server" ];
          };
        };
      };
    };
  };
}
