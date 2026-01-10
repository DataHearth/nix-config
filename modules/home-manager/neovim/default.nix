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

    programs.neovim = {
      enable = true;
      defaultEditor = cfg.defaultEditor;

      viAlias = true;
      vimAlias = true;

      withNodeJs = true;
      withPerl = true;
      withPython3 = true;
      withRuby = true;

      plugins = with pkgs.vimPlugins; [
        lazy-nvim
      ];
      extraPackages = with pkgs; [
        git
        gcc
        gnumake
        unzip

        # lazy.nvim
        luajitPackages.luarocks

        # telescope.nvim
        fd

        # yazi.nvim
        yazi

        # conform.nvim
        stylua
        nixfmt
        prettierd
        eslint_d
        taplo
        ruff
        shfmt
        shellcheck
        sqlfluff
        golangci-lint

        # LSP servers
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
      ];
    };
  };
}
