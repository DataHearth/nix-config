{ config, lib, ... }:
let
  cfg = config.home_modules.ghostty;

  enable = lib.mkEnableOption "ghostty";
in
{
  options.home_modules.ghostty = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      installVimSyntax = true;
      settings = {
        background-opacity = 0.9;
        theme = "catppuccin-macchiato";
        font-family = "Mononoki Nerd Font";
        link-url = true;
        # clipboard-read = "allow";
        # clipboard-write = "allow";
        copy-on-select = "clipboard";
      };
    };
  };
}
