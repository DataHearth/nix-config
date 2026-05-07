{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.zed-editor;
  shared = import ../../lib { inherit pkgs lib; };
  inherit (shared) lsp;
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
      mutableUserKeymaps = false;

      userKeymaps = [
        {
          bindings = {
            "ctrl-shift-b" = "workspace::ToggleLeftDock";
          };
        }
      ];

      # LSPs, formatters, and tools available in Zed's environment
      extraPackages = lib.concatLists (
        map (l: l.packages ++ l.deps) (builtins.attrValues lsp)
      );

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
        "zig"
        "proto"
        "rainbow-csv"
        "helm"
        "docker-compose"
        "make"
        "html"
        "css"
        "env"
        "log"
        "markdown-oxide"
        "basher"

        # Version control
        "git-firefly"
        "jjdescription"
      ];

      userSettings = {
        vim_mode = true;
        base_keymap = "VSCode";

        agent_servers = {
          claude-acp = {
            type = "registry";
            env = {
              CLAUDE_CODE_EXECUTABLE = lib.getExe pkgs.claude-code;
            };
          };
        };

        # Kill Zed's own AI (Zeta predictions, cloud assistant). Keep agent panel for claude-code.
        edit_predictions = {
          provider = "none";
        };
        show_edit_predictions = false;

        # Use nixpkgs node instead of Zed downloading prebuilt binary
        # (fails on NixOS due to dynamic linker mismatch)
        node = {
          path = lib.getExe pkgs.nodejs;
          npm_path = "${pkgs.nodejs}/bin/npm";
        };

        project_panel = {
          hide_root = true;
        };

        diagnostics = {
          inline.enabled = true;
        };

        # Disable telemetry
        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        # Appearance
        ui_font_size = 16;
        buffer_font_size = 15;
        buffer_font_family = "Mononoki Nerd Font";
        tab_size = 2;
        show_wrap_guides = true;
        wrap_guides = [ 120 ];
        indent_guides.enabled = true;
        inlay_hints = {
          enabled = true;
          show_type_hints = true;
          show_parameter_hints = true;
          show_other_hints = true;
        };

        # Behavior
        format_on_save = "on";
        linked_edits = true;
        prettier.allowed = false;
        preview_tabs.enabled = false;
        confirm_quit = true;

        # Terminal
        terminal = {
          font_family = "Mononoki Nerd Font";
          font_size = 14;
          blinking = "on";
          copy_on_select = true;
        };

        # Tab bar
        tab_bar.show = true;
        tabs = {
          git_status = true;
          file_icons = true;
          close_position = "right";
        };

        # Scrollbar
        scrollbar.show = "auto";

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
          git_gutter = "tracked_files";
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

        # LSP settings
        lsp = {
          jj_lsp = {
            binary = {
              path = lib.getExe pkgs.jj-lsp;
              arguments = [ ];
            };
          };
          rust-analyzer = {
            initialization_options = {
              check.command = "clippy";
            };
          };
          vtsls = {
            initialization_options = {
              typescript.inlayHints = {
                parameterNames.enabled = "all";
                variableTypes.enabled = true;
                propertyDeclarationTypes.enabled = true;
                functionLikeReturnTypes.enabled = true;
                enumMemberValues.enabled = true;
              };
            };
          };
        };

        # Language-specific settings
        languages = {
          Nix = {
            language_servers = [
              "nixd"
              "!nil"
            ];
          };
          Rust = {
            language_servers = [ "rust-analyzer" ];
          };
          Go = {
            formatter = "language_server";
            language_servers = [ "gopls" ];
          };
          Python = {
            language_servers = [
              "pyright"
              "ruff"
            ];
            formatter = "language_server";
          };
          TypeScript = {
            language_servers = [
              "vtsls"
              "eslint"
            ];
          };
          Lua = {
            language_servers = [ "lua-language-server" ];
            formatter = "language_server";
          };
          Zig = {
            language_servers = [ "zls" ];
            formatter = "language_server";
          };
          Helm = {
            language_servers = [ "helm-ls" ];
          };
          Proto = {
            language_servers = [ "protobuf-language-server" ];
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
