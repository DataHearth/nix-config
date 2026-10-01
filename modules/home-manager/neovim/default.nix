{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.home_modules.neovim;

  enable = lib.mkEnableOption "neovim";
  defaultEditor = lib.mkOption {
    type = lib.types.bool;
    default = false;
    example = true;
    description = "Set NeoVim as default editor";
  };

  # Keys must equal lazy.nvim's plugin names (repo basename, or the spec's
  # `name`): lazy resolves each spec to `<dev.path>/<name>`.
  lazyPlugins = pkgs.linkFarm "lazy-plugins" (
    with pkgs.vimPlugins;
    {
      "blink.cmp" = blink-cmp;
      "bufferline.nvim" = bufferline-nvim;
      "catppuccin" = catppuccin-nvim;
      "conform.nvim" = conform-nvim;
      "diffview.nvim" = diffview-nvim;
      "dropbar.nvim" = dropbar-nvim;
      "flash.nvim" = flash-nvim;
      "friendly-snippets" = friendly-snippets;
      "gitsigns.nvim" = gitsigns-nvim;
      "lualine.nvim" = lualine-nvim;
      "mini.ai" = mini-ai;
      "noice.nvim" = noice-nvim;
      "nui.nvim" = nui-nvim;
      "nvim-autopairs" = nvim-autopairs;
      "nvim-lint" = nvim-lint;
      "nvim-surround" = nvim-surround;
      "nvim-ufo" = nvim-ufo;
      "nvim-web-devicons" = nvim-web-devicons;
      "persistence.nvim" = persistence-nvim;
      "plenary.nvim" = plenary-nvim;
      "promise-async" = promise-async;
      "render-markdown.nvim" = render-markdown-nvim;
      "schemastore.nvim" = SchemaStore-nvim;
      "snacks.nvim" = snacks-nvim;
      "telescope-fzf-native.nvim" = telescope-fzf-native-nvim;
      "todo-comments.nvim" = todo-comments-nvim;
      "trouble" = trouble-nvim;
      "which-key.nvim" = which-key-nvim;
      "yazi.nvim" = yazi-nvim;
    }
  );
in
{
  options.home_modules.neovim = {
    inherit enable defaultEditor;
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."nvim" = {
      source = ./nvim;
      recursive = true;
    };
    xdg.configFile."nvim/lua/nix-paths.lua".text = ''
      return {
        lazy = "${pkgs.vimPlugins.lazy-nvim}",
        plugins = "${lazyPlugins}",
      }
    '';

    programs.neovim = {
      enable = true;
      inherit (cfg) defaultEditor;

      viAlias = true;
      vimAlias = true;

      withPython3 = false;
      withRuby = false;

      plugins = with pkgs.vimPlugins; [
        (nvim-treesitter.withPlugins (
          p: with p; [
            bash
            c
            css
            diff
            dockerfile
            go
            gomod
            gosum
            html
            javascript
            jsdoc
            json
            lua
            luadoc
            markdown
            markdown_inline
            nix
            python
            query
            regex
            rust
            svelte
            toml
            tsx
            typescript
            vim
            vimdoc
            yaml
          ]
        ))
        nvim-treesitter-textobjects
      ];

      extraPackages = with pkgs; [
        git

        # snacks.picker
        fd

        # yazi.nvim
        yazi

        # conform.nvim
        stylua
        nixfmt
        biome
        prettierd
        taplo
        ruff
        shfmt
        sqlfluff
        golangci-lint

        # nvim-lint
        shellcheck

        bash-language-server
        dockerfile-language-server
        vscode-langservers-extracted # html, css, json, eslint
        htmx-lsp
        lua-language-server
        nixd
        pyright
        svelte-language-server
        tailwindcss-language-server
        yaml-language-server
        typescript-language-server
        gopls
        rust-analyzer
      ];
    };
  };
}
