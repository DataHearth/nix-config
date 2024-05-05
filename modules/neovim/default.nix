{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.neovim;

  enable = mkEnableOption "neovim";
  defaultEditor = mkOption {
    type = types.bool;
    description = "Make NeoVim the default editor";
    default = true;
  };
  colorscheme = mkOption {
    type = types.str;
    description = "Neovim colorscheme";
    default = "catppuccin";
  };
in {
  options.custom.neovim = { inherit enable colorscheme defaultEditor; };

  config = mkIf cfg.enable {
    environment = {
      variables.EDITOR = mkIf cfg.defaultEditor "nvim";
      systemPackages = with pkgs; [
        prettierd
        eslint_d
        gofumpt
        golines
        ruff
        stylua
        nixfmt-classic
        taplo
        rustfmt
      ];
    };

    programs.nixvim = {
      enable = true;
      type = "lua";
      viAlias = true;
      vimAlias = true;
      colorscheme = cfg.colorscheme;
      globals = { mapleader = " "; };
      opts = {
        tabstop = 2;
        expandtab = true;
        softtabstop = 2;
        shiftwidth = 2;
        number = true;
      };
      colorschemes.catppuccin = {
        enable = true;
        settings = {
          transparent_background = true;
          flavour = "macchiato";
        };
      };
      keymaps = import ./keymaps;
      plugins = {
        barbecue.enable = true;
        chadtree.enable = true;
        cmp = import ./plugins/cmp.nix { lib = lib; };
        cmp-buffer.enable = true;
        cmp-nvim-lsp-signature-help.enable = true;
        cmp-nvim-lsp.enable = true;
        cmp-nvim-lua.enable = true;
        cmp-path.enable = true;
        cmp_luasnip.enable = true;
        comment.enable = true;
        copilot-cmp.enable = true;
        copilot-lua = import ./plugins/copilot-lua.nix;
        crates-nvim.enable = true;
        dashboard = import ./plugins/dashboard.nix;
        diffview.enable = true;
        gitsigns = import ./plugins/gitsigns.nix;
        illuminate.enable = true;
        indent-blankline = import ./plugins/indent-blankline.nix;
        leap.enable = true;
        lsp = import ./plugins/lsp.nix;
        lspkind.enable = true;
        lualine.enable = true;
        luasnip = {
          enable = true;
          fromVscode = [{ paths = ./snippets; }];
        };
        nix.enable = true;
        nvim-autopairs.enable = true;
        telescope = import ./plugins/telescope.nix;
        todo-comments.enable = true;
        treesitter.enable = true;
        trouble = import ./plugins/trouble.nix;

        # Custom
        harpoon = {
          enable = true;
          package = pkgs.vimUtils.buildVimPlugin {
            name = "harpoon2";
            src = pkgs.fetchFromGitHub {
              owner = "ThePrimeagen";
              repo = "harpoon";
              rev = "a38be6e0dd4c6db66997deab71fc4453ace97f9c";
              hash = "sha256-RjwNUuKQpLkRBX3F9o25Vqvpu3Ah1TCFQ5Dk4jXhsbI=";
            };
          };
        };
      };
      extraConfigLua = ''
        require("formatter").setup {
          logging = true,
          log_level = vim.log.levels.WARN,
          filetype = {
            css = {
              require("formatter.filetypes.css").prettierd,
              require("formatter.filetypes.css").eslint_d,
            },
            go = {
              require("formatter.filetypes.go").gofumpt,
              require("formatter.filetypes.go").golines,
            },
            html = {
              require("formatter.filetypes.html").prettierd,
            },
            javascript = {
              require("formatter.filetypes.javascript").prettierd,
              require("formatter.filetypes.javascript").eslint_d,
            },
            json = {
              require("formatter.filetypes.json").prettierd,
            },
            lua = {
              require("formatter.filetypes.lua").stylua,
            },
            nix = {
              require("formatter.filetypes.nix").nixfmt,
            },
            python = {
              require("formatter.filetypes.python").ruff,
            },
            rust = {
              require("formatter.filetypes.rust").rustfmt,
            },
            svelte = {
              require("formatter.filetypes.svelte").prettier,
            },
            toml = {
              require("formatter.filetypes.toml").taplo,
            },
            typescript = {
              require("formatter.filetypes.typescript").prettierd,
            },
            ["*"] = {
              require("formatter.filetypes.any").remove_trailing_whitespace,
              vim.lsp.buf.format,
            }
          }
        }

        local augroup = vim.api.nvim_create_augroup
        local autocmd = vim.api.nvim_create_autocmd
        augroup("__formatter__", { clear = true })
        autocmd("BufWritePost", {
          group = "__formatter__",
          command = ":FormatWrite",
        })
      '';
      extraPlugins = with pkgs.vimPlugins; [ formatter-nvim ];
    };
  };
}
