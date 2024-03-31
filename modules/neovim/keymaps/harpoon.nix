[
  {
    action = ''
    function()
      local conf = require("telescope.config").values
      local file_paths = {}
      for _, item in ipairs(require("harpoon"):list().items) do
          table.insert(file_paths, item.value)
      end

      require("telescope.pickers").new({}, {
          prompt_title = "Harpoon",
          finder = require("telescope.finders").new_table({
              results = file_paths,
          }),
          previewer = conf.file_previewer({}),
          sorter = conf.generic_sorter({}),
      }):find()
    end
    '';
    key = "<leader>e";
    lua = true;
  }
  {
    action = "function() require('harpoon'):list():append() end";
    key = "<leader>a";
    lua = true;
  }
  {
    action = "function() require('harpoon'):list():prev() end";
    key = "<leader>p";
    lua = true;
  }
  {
    action = "function() require('harpoon'):list():next() end";
    key = "<leader>n";
    lua = true;
  }
  {
    action = "function() require('harpoon'):list():clear() end";
    key = "<leader>c";
    lua = true;
  }
]
