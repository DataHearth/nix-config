{ lib, ... }:
{
  enable = true;
  settings = {
    mapping = {
      "<C-Space>" = "cmp.mapping.complete()";
      "<CR>" = "cmp.mapping.confirm({ select = false })";
      "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
      "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
      "<C-e>" = "cmp.mapping(cmp.mapping.abort(), {'i', 's'})";
    };
    sources = [
      { name = "nvim_lsp"; }
      { name = "luasnip"; }
      { name = "path"; }
      { name = "buffer"; }
      { name = "copilot"; }
      { name = "cmdline"; }
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
    formatting = {
      fields = [ "kind" "abbr" "menu" ];
      format = lib.mkForce ''
        function(entry, vim_item)
          local kind = require("lspkind").cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
          local strings = vim.split(kind.kind, "%s", { trimempty = true })
          kind.kind = " " .. (strings[1] or "") .. " "
          kind.menu = "    (" .. (strings[2] or "") .. ")"

          return kind
        end
      '';
    };
    window = {
      completion = {
        winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None";
        col_offset = -3;
        side_padding = 0;
      };
    };
  };
}
