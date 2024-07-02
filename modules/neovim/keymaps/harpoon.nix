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
    options.desc = "Open harpoon floating window with telescope";
  }
  {
    action.__raw = "function() require('harpoon'):list():add() end";
    key = "<leader>ha";
    options.desc = "Harpoon - Add current file";
  }
  {
    action.__raw = "function() require('harpoon'):list():remove() end";
    key = "<leader>hr";
    options.desc = "Harpoon - Remove current file";
  }
  {
    action.__raw = "function() require('harpoon'):list():prev() end";
    key = "<leader>hp";
    options.desc = "Harpoon - Go to previous file";
  }
  {
    action.__raw = "function() require('harpoon'):list():next() end";
    key = "<leader>hn";
    options.desc = "Harpoon - Go to next file";
  }
  {
    action.__raw = "function() require('harpoon'):list():clear() end";
    key = "<leader>hc";
    options.desc = "Harpoon - Clear list";
  }
]
