{
  enable = true;
  sources = [
    {name = "nvim_lsp";}
    {name = "path";}
    {name = "buffer";}
    {name = "luasnip";}
    {name = "cmdline";}
    {name = "copilot.lua";}
    {name = "crates";}
  ];
  mapping = {
    "<C-Space>" = "cmp.mapping.complete()";
    "<CR>" = "cmp.mapping.confirm({ select = true })";
    "<S-Tab>" = {
      action = "cmp.mapping.select_prev_item()";
      modes = [
        "i"
        "s"
      ];
    };
    "<Tab>" = {
      action = "cmp.mapping.select_next_item()";
      modes = [
        "i"
        "s"
      ];
    };
    "<C-e>" = {
      action = "cmp.mapping.abort()";
      modes = [
        "i"
        "s"
      ];
    };
  };
  snippet.expand = "luasnip";
}
