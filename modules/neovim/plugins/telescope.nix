{
  plugins.telescope = {
    enable = true;
    keymaps = {
      "<leader>ff" = {
        action = "find_files";
        options.desc = "Find files in workspace";
      };
      "<leader>fg" = {
        action = "git_files";
        options.desc = "Find files in git files";
      };
      "<leader>fc" = {
        action = "live_grep";
        options.desc = "Find files containing a code pattern - regex";
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
  };
}
