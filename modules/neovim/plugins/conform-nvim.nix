{
  enable = true;
  logLevel = "error";
  formatOnSave = {
    lspFallback = true;
    timeoutMs = 1000;
  };
  formattersByFt = {
    lua = [ "stylua" ];
    go = [ "gofumpt" "golines" ];
    javascript = [ "prettier" "eslint_d" ];
    typescript = [ "prettier" "eslint_d" ];
    css = [ "prettier" ];
    html = [ "prettier" ];
    json = [ "prettier" ];
    nix = [ "nixfmt" ];
    python = [ "ruff_format" ];
    rust = [ "rustfmt" ];
    svelte = [ "prettier" "eslint_d" ];
    toml = [ "taplo" ];
    "_" = [ "trim_whitespace" ];
  };

}
