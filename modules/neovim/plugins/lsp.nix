{
  enable = true;
  servers = {
    bashls.enable = true;
    dockerls.enable = true;
    gopls.enable = true;
    html.enable = true;
    htmx.enable = true;
    jsonls.enable = true;
    lua-ls.enable = true;
    nixd.enable = true;
    ruff-lsp.enable = true;
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
}
