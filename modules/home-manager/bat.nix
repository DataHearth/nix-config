{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.bat;
in
{
  options.home_modules.bat = {
    enable = lib.mkEnableOption "bat with Catppuccin Macchiato theme";
  };

  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config.theme = "catppuccin_macchiato";

      themes.catppuccin_macchiato = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
          sha256 = "1g2r6j33f4zys853i1c5gnwcdbwb6xv5w6pazfdslxf69904lrg9";
        };
        file = "Catppuccin-macchiato.tmTheme";
      };
    };
  };
}
