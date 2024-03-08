{
  enable = true;
  settings = {
    mapping = {
      "<C-Space>" = "cmp.mapping.complete()";
      "<CR>" = "cmp.mapping.confirm({ select = true })";
      "<S-Tab>" = "cmp.mapping.select_prev_item(), {'i', 's'}";
      "<Tab>" = "cmp.mapping.select_next_item(), {'i', 's'}";
    };
    sources = [
      { name = "nvim_lsp"; }
      { name = "luasnip"; }
      { name = "path"; }
      { name = "buffer"; }
      { name = "copilot"; }
      { name = "crates"; }
    ];
  };
}
