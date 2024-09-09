{
  enable = true;
  logLevel = "error"; 
  formattersByFt = {
    lua = [ "stylua" ];
    go = [ "gofumpt" "golines" ];
    javascript = [ "prettierd" "eslint" ];
    typescript = [ "prettierd" "eslint" ];
    css = [ "prettierd" ];
    html = [ "prettierd" ];
    json = [ "prettierd" ];
    nix = [ "nixfmt" ];
    python = [ "ruff_format" ];
    rust = [ "rustfmt" ];
    svelte = [ "prettierd" "eslint" ];
    toml = [ "taplo" ];
    "_" = [ "trim_whitespace" ];
  };
  formatOnSave = {};
}
