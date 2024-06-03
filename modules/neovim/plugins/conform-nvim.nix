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
    javascript = [ "prettierd" "eslint_d" ];
    typescript = [ "prettierd" "eslint_d" ];
    css = [ "prettierd" ];
    html = [ "prettierd" ];
    json = [ "prettierd" ];
    nix = [ "nixfmt" ];
    python = [ "ruff_format" ];
    rust = [ "rustfmt" ];
    svelte = [ "prettierd" "eslint_d" ];
    toml = [ "taplo" ];
    "_" = [ "trim_whitespace" ];
  };

}
