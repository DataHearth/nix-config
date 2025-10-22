{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.hyprlock;

  enable = lib.mkEnableOption "hyprlock";
  lockBackgroundImage = lib.mkOption {
    type = lib.types.nullOr lib.types.nonEmptyStr;
    description = "Path to background image for lock screen";
    default = null;
  };
  defaultDisplay = lib.mkOption {
    type = lib.types.nullOr lib.types.nonEmptyStr;
    description = "Default display will have all labels and input-labels written on.";
    default = null;
  };
in
{
  options.home_modules.hyprlock = {
    inherit enable lockBackgroundImage defaultDisplay;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      playerctl
    ];

    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          grace = 0;
          hide_cursor = true;
          ignore_empty_input = false;
        };

        background = [
          {
            path = lib.mkIf (cfg.lockBackgroundImage != null) cfg.lockBackgroundImage;
            blur_passes = 3;
            blur_size = 8;
            contrast = 0.8916;
            brightness = 0.8172;
            vibrancy = 0.1696;
            vibrancy_darkness = 0.0;
            noise = 1.17e-2;
          }
        ];

        input-field = [
          {
            monitor = lib.mkIf (cfg.defaultDisplay != null) cfg.defaultDisplay;
            size = "250, 60";
            outline_thickness = 2;
            dots_size = 0.2;
            dots_spacing = 0.2;
            dots_center = true;
            dots_rounding = -1;
            outer_color = "rgba(0, 0, 0, 0)";
            inner_color = "rgba(0, 0, 0, 0.5)";
            font_color = "rgb(200, 200, 200)";
            fade_on_empty = true;
            fade_timeout = 2000;
            placeholder_text = ''<i><span foreground="##cdd6f4">Input Password...</span></i>'';
            rounding = -1;
            check_color = "rgb(204, 136, 34)";
            fail_color = "rgb(204, 34, 34)";
            fail_text = "<i>$FAIL</i>";
            capslock_color = -1;
            numlock_color = -1;
            bothlock_color = -1;
            invert_numlock = false;
            swap_font_color = false;
            position = "0, -120";
            halign = "center";
            valign = "center";
            shadow_passes = 0;
            shadow_size = 3;
            shadow_color = "rgba(0, 0, 0, 1.0)";
            shadow_boost = 1.2;
            hide_input = false;
          }
        ];

        label = [
          {
            monitor = lib.mkIf (cfg.defaultDisplay != null) cfg.defaultDisplay;
            text = ''cmd[update:1000] echo "$TIME"'';
            font_family = "Mononoki Nerd Font";
            color = "rgba(255, 255, 255, 0.6)";
            font_size = 120;
            position = "0, -300";
            valign = "top";
            halign = "center";
            shadow_passes = 0;
            shadow_size = 3;
            shadow_color = "rgba(0, 0, 0, 1.0)";
            shadow_boost = 1.2;
          }
          {
            monitor = lib.mkIf (cfg.defaultDisplay != null) cfg.defaultDisplay;
            text = "Hello there, $USER";
            font_family = "Mononoki Nerd Font";
            color = "rgba(255, 255, 255, 0.6)";
            font_size = 25;
            position = "0, -40";
            halign = "center";
            valign = "center";
            shadow_passes = 0;
            shadow_size = 3;
            shadow_color = "rgba(0, 0, 0, 1.0)";
            shadow_boost = 1.2;
          }
          {
            monitor = lib.mkIf (cfg.defaultDisplay != null) cfg.defaultDisplay;
            text = ''cmd[update:1000] playerctl metadata --format "{{ artist }} - {{ album }} - {{ title }}"'';
            color = "rgba(255, 255, 255, 0.6)";
            font_size = 18;
            font_family = "Mononoki Nerd Font";
            position = "0, -50";
            valign = "bottom";
            halign = "center";
            shadow_passes = 0;
            shadow_size = 3;
            shadow_color = "rgba(0, 0, 0, 1.0)";
            shadow_boost = 1.2;
          }
        ];

        auth = {
          fingerprint = {
            enabled = true;
          };
        };
      };
    };
  };
}
