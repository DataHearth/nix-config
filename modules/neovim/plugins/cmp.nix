{
  enable = true;
  settings = {
    mapping = {
      "<C-Space>" = "cmp.mapping.complete()";
      "<CR>" = "cmp.mapping.confirm({ select = false })";
      "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
      "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
    };
    sources = [
      { name = "nvim_lsp"; }
      { name = "luasnip"; }
      { name = "path"; }
      { name = "buffer"; }
      { name = "copilot"; }
      { name = "crates"; }
    ];
    completion = {
      keyword_length = 3;
    };
    preselect = "cmp.PreselectMode.None";
    snippet.expand = ''
      function(args)
        require('luasnip').lsp_expand(args.body)
      end
    '';
  };
}
