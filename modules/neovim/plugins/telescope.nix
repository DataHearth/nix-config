{
  enable = true;
  keymaps = {
    "<leader>ff" = {
      action = "find_files";
      options.desc = "Find files in workspace";
    };
    "<leader>fg" = {
      action = "live_grep";
      options.desc = "Find files in workspace - regex";
    };
    "<leader>fb" = {
      action = "buffers";
      options.desc = "Find buffered files";
    };
    "<leader>fh" = {
      action = "help_tags";
      options.desc = "Command help tags";
    };
  };
}
