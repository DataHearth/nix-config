{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.alacritty;

  enable = lib.mkEnableOption "alacritty";
  package = lib.mkPackageOption pkgs "alacritty" {
    nullable = true;
  };
in
{
  options.home_modules.alacritty = {
    inherit enable package;
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      package = lib.mkIf (cfg.package != null) cfg.package;

      settings = {
        general.import = [
          (builtins.fetchurl {
            url = "https://raw.githubusercontent.com/catppuccin/alacritty/832787d6cc0796c9f0c2b03926f4a83ce4d4519b/catppuccin-macchiato.toml";
            sha256 = "1iq187vg64h4rd15b8fv210liqkbzkh8sw04ykq0hgpx20w3qilv";
          })
        ];
        env.TERM = "xterm-256color";
        scrolling.multiplier = 5;
        selection.save_to_clipboard = true;

        font = {
          size = 12;
          normal.family = "Mononoki Nerd Font";
        };

        window = {
          opacity = lib.mkDefault 0.9;
          startup_mode = "Maximized";
        };
      };
    };
  };
}
