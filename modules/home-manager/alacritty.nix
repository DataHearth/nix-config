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
        env.TERM = "xterm-256color";
        scrolling.multiplier = 5;
        selection.save_to_clipboard = true;

        cursor = {
          style = {
            shape = "Beam";
            blinking = "On";
          };
          blink_interval = 500;
        };

        font = {
          size = 12;
          normal.family = "Mononoki Nerd Font";
        };

        keyboard.bindings = [
          {
            key = "Return";
            mods = "Shift";
            chars = "\n";
          }
        ];

        window = {
          opacity = lib.mkDefault 0.9;
          startup_mode = "Maximized";
          padding = {
            x = 8;
            y = 8;
          };
          dynamic_padding = true;
        };
      };
    };
  };
}
