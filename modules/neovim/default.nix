{ lib, config, options, pkgs, ...}:
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
in
{
  options.custom.neovim = {
    inherit enable colorscheme defaultEditor;
  };

  config = mkIf cfg.enable {
    environment.variables.EDITOR = mkIf cfg.defaultEditor "nvim";

    programs.nixvim = {
      enable = true;
      type = "lua";
      viAlias = true;
      vimAlias = true;
      colorscheme = cfg.colorscheme;
      globals = {
        mapleader = " ";
      };
      options = {
        tabstop = 2;
        expandtab = true;
        softtabstop = 2;
        shiftwidth = 2;
        number = true;
      };
      colorschemes.catppuccin = {
        enable = true;
        transparentBackground = true;
        flavour = "macchiato";
      };
      keymaps = [
        {
          action = "<cmd>CHADopen<cr>";
          key = "<C-t>";
        }
        {
          action = "<cmd>TroubleToggle<cr>";
          key = "<C-S-t>";
        }
        {
          action = "<cmd>lua vim.lsp.buf.hover()<cr>";
          key = "<S-k>";
        }
        {
          action = ''
          function()
            local conf = require("telescope.config").values
            local file_paths = {}
            for _, item in ipairs(require("harpoon"):list().items) do
                table.insert(file_paths, item.value)
            end

            require("telescope.pickers").new({}, {
                prompt_title = "Harpoon",
                finder = require("telescope.finders").new_table({
                    results = file_paths,
                }),
                previewer = conf.file_previewer({}),
                sorter = conf.generic_sorter({}),
            }):find()
          end
          '';
          key = "<C-e>";
          lua = true;
        }
        {
          action = "function() require('harpoon'):list():append() end";
          key = "<leader>a";
          lua = true;
        }
        {
          action = "function() require('harpoon'):list():prev() end";
          key = "<leader>p";
          lua = true;
        }
        {
          action = "function() require('harpoon'):list():next() end";
          key = "<leader>n";
          lua = true;
        }
        {
          action = "function() require('harpoon'):list():clear() end";
          key = "<leader>c";
          lua = true;
        }
       {
         action = "<cmd>lua vim.lsp.buf.format()<cr>";
         key = "<leader>s";
       }
      ];
      plugins = {
        diffview.enable = true;
        chadtree.enable = true;
        leap.enable = true;
        nix.enable = true;
        comment.enable = true;
        todo-comments.enable = true;
        lualine.enable = true;
        luasnip.enable = true;
        nvim-autopairs.enable = true;
        illuminate.enable = true;
        copilot-cmp.enable = true;
        cmp_luasnip.enable = true;
        cmp-nvim-lsp.enable = true;
        cmp-cmdline.enable = true;
        cmp-path.enable = true;
        cmp-buffer.enable = true;
        crates-nvim.enable = true;
        treesitter.enable = true;
        telescope = import ./plugins/telescope.nix;
        trouble = import ./plugins/trouble.nix;
        indent-blankline = import ./plugins/indent-blankline.nix;
        dashboard = import ./plugins/dashboard.nix;
        gitsigns = import ./plugins/gitsigns.nix;
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

        # Completion
        lsp = import ./plugins/lsp.nix;

        ## CMP
        cmp = import ./plugins/cmp.nix;

        ### Thirdparties
        copilot-lua = import ./plugins/copilot-lua.nix;
      };
    };
  };
}
