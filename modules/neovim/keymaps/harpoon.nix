[
  {
    action.__raw = ''
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
  }
  {
    action.__raw = "function() require('harpoon'):list():append() end";
    key = "<leader>ha";
  }
  {
    action.__raw = "function() require('harpoon'):list():prev() end";
    key = "<leader>hp";
  }
  {
    action.__raw = "function() require('harpoon'):list():next() end";
    key = "<leader>hn";
  }
  {
    action.__raw = "function() require('harpoon'):list():clear() end";
    key = "<leader>hc";
  }
]
