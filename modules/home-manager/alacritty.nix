{ config, lib, ... }:
let
  cfg = config.home_modules.alacritty;

  enable = lib.mkEnableOption "alacritty";
in
{
  options.home_modules.alacritty = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        general.import = [
          (builtins.fetchurl {
            url = "https://raw.githubusercontent.com/catppuccin/alacritty/832787d6cc0796c9f0c2b03926f4a83ce4d4519b/catppuccin-macchiato.toml";
            sha256 = "1iq187vg64h4rd15b8fv210liqkbzkh8sw04ykq0hgpx20w3qilv";
          })
        ];
        env.TERM = "xterm-256color";
        font = {
          size = 12;
          normal.family = "Mononoki Nerd Font";
        };
        scrolling.multiplier = 5;
        selection.save_to_clipboard = true;
        window.opacity = lib.mkDefault 0.9;
      };
    };
  };
}
