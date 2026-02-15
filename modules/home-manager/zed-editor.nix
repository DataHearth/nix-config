{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.zed-editor;

  enable = lib.mkEnableOption "zed-editor";
  package = lib.mkPackageOption pkgs "zed-editor" {
    nullable = true;
  };
in
{
  options.home_modules.zed-editor = {
    inherit enable package;
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      package = lib.mkIf (cfg.package != null) cfg.package;

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

        # Version control
        "jj-lsp"
        "git-firefly"

        # Theme
        "catppuccin"
      ];

      userSettings = {
        vim_mode = true;
        base_keymap = "VSCode";

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

        # Behavior
        autosave = {
          after_delay.milliseconds = 1000;
        };
        linked_edits = true;
        prettier.allowed = false;

        # Git
        git.inline_blame.enabled = true;

        # File types
        file_types = {
          markdown = [ "*.mdx" ];
          plaintext = [ "LICENSE" ];
        };

        # Language-specific settings
        languages = {
          Nix = {
            language_servers = [ "nixd" "!nil" ];
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
