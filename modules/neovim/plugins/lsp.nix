{
  plugins.lsp = {
    enable = true;
    servers = {
      bashls.enable = true;
      dockerls.enable = true;
      eslint.enable = true;
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
      ts-ls.enable = true;
      yamlls.enable = true;
    };
    keymaps = {
      lspBuf = {
        "<S-k>" = "hover";
        "<leader>a" = "code_action";
        "<leader>r" = "rename";
        "<leader>gd" = "definition";
        "<leader>gD" = "declaration";
        "<leader>gr" = "references";
      };
    };
    postConfig = ''
      local lsp = vim.lsp;
      lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, {
        border = "rounded",
      })
      lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, {
        border = "rounded",
      })
    '';
  };
}
