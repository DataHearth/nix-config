{
  plugins.conform-nvim = {
    enable = true;
    settings = {
      log_level = "error";
      formatters_by_ft = {
        lua = [ "stylua" ];
        go = [
          "gofumpt"
          "golines"
        ];
        javascript = [
          "prettierd"
          "eslint"
        ];
        typescript = [
          "prettierd"
          "eslint"
        ];
        css = [ "prettierd" ];
        html = [ "prettierd" ];
        json = [ "prettierd" ];
        nix = [ "nixfmt" ];
        python = [ "ruff_format" ];
        rust = [ "rustfmt" ];
        svelte = [
          "prettierd"
          "eslint"
        ];
        toml = [ "taplo" ];
        "_" = [ "trim_whitespace" ];
      };
      format_on_save = { };
    };
  };
}
