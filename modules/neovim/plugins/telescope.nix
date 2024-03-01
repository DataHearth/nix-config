{
  enable = true;
  keymaps = {
    "<leader>ff" = {
      action = "find_files";
      desc = "Find files in workspace";
    };
    "<leader>fg" = {
      action = "live_grep";
      desc = "Find files in workspace - regex";
    };
    "<leader>fb" = {
      action = "buffers";
      desc = "Find buffered files";
    };
    "<leader>fh" = {
      action = "help_tags";
      desc = "Command help tags";
    };
  };
}
