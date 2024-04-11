{
  enable = true;
  servers = {
    bashls.enable = true;
    dockerls.enable = true;
    gopls = {
      enable = true;
      extraOptions = {
        staticcheck = true;
        gofumpt = true;
        analyses = {
          unusedvariable = true;
        };
      };
    };
    html.enable = true;
    htmx.enable = true;
    jsonls.enable = true;
    lua-ls.enable = true;
    nixd.enable = true;
    ruff-lsp.enable = true;
    pyright.enable = true;
    rust-analyzer = {
      enable = true;
      installCargo = true;
      installRustc = true;
    };
    svelte.enable = true;
    tailwindcss.enable = true;
    taplo.enable = true;
    tsserver.enable = true;
    yamlls.enable = true;
  };
  keymaps = {
    lspBuf = {
      "<S-k>" = "hover";
      "<leader>f" = "format";
      "<leader>a" = "code_action";
      "<leader>r" = "rename";
      "<leader>gd" = "declaration";
      "<leader>gr" = "references";
    };
  };
}
