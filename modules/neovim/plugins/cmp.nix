{ lib, ... }:
{
  plugins.cmp = {
    enable = true;
    settings = {
      mapping = {
        "<C-Space>" = "cmp.mapping.complete()";
        "<CR>" = "cmp.mapping.confirm({ select = false })";
        "<Down>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
        "<Up>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
        "<C-e>" = "cmp.mapping(cmp.mapping.abort(), {'i', 's'})";
        "<Tab>" = ''
          cmp.mapping(function(fallback)
            local luasnip = require("luasnip")
            if luasnip.jumpable(1) then
              luasnip.jump(1)
            else
              fallback()
            end
          end, {'i', 's'})
        '';
        "<S-Tab>" = ''
          cmp.mapping(function(fallback)
            local luasnip = require("luasnip")
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, {'i', 's'})
        '';
      };
      sources = [
        { name = "buffer"; }
        { name = "luasnip"; }
        { name = "nvim_lsp"; }
        { name = "nvim_lsp_signature_help"; }
        { name = "nvim_lua"; }
        { name = "path"; }
      ];
      completion = {
        keyword_length = 2;
      };
      preselect = "cmp.PreselectMode.None";
      snippet.expand = ''
        function(args)
          require('luasnip').lsp_expand(args.body)
        end
      '';
      formatting = {
        fields = [
          "kind"
          "abbr"
          "menu"
        ];
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
          border = "rounded";
        };
        window =
          let
            bordered = {
              border = "rounded";
              col_offset = 0;
              scrollbar = true;
              scrolloff = 0;
              side_padding = 1;
              winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None";
              zindex = 1001;
            };
          in
          {
            completion = bordered;
            documentation = bordered;
          };
      };
    };
  };
}
