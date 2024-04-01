{ config, options, lib, ... }:
with lib;
let
  cfg = config.hm.hyprlock;

  enable = mkEnableOption "hyprlock";
  lockBackgroundImage = mkOption {
    type = types.str;
    description = "Path to background image for lock screen";
    default = "";
  };
  defaultDisplay = mkOption {
    type = types.str;
    description = "Default display will have all labels and input-labels written on.";
    default = "";
  };
in
{
  options.hm.hyprlock = {
    inherit enable lockBackgroundImage defaultDisplay;
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      general.disable_loading_bar = true;

      backgrounds = [
        {
          path = mkIf (cfg.lockBackgroundImage != "") cfg.lockBackgroundImage;
          blur_passes = 3;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }
      ];
      
      input-fields = [
        {
          monitor = mkIf (cfg.defaultDisplay != "") cfg.defaultDisplay;
          size = {
            width = 250;
            height = 60;
          };
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.2;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(0, 0, 0, 0.5)";
          font_color = "rgb(200, 200, 200)";
          placeholder_text = "<i><span foreground=\"##cdd6f4\">Input Password...</span></i>";
          position = {
            x = 0;
            y = -120;
          };
        }
      ];

      labels = [
        {
          monitor = mkIf (cfg.defaultDisplay != "") cfg.defaultDisplay;
          text = "cmd[update:1000] echo \"$TIME\"";
          font_family = "Mononoki Nerd Font";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 120;
          position = {
            x = 0;
            y = -300;
          };
          valign = "top";
        }
        {
          monitor = mkIf (cfg.defaultDisplay != "") cfg.defaultDisplay;
          text = "Hello there, $USER";
          font_family = "Mononoki Nerd Font";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 25;
          position = {
            x = 0;
            y = -40;
          };
        }
        {
          monitor = mkIf (cfg.defaultDisplay != "") cfg.defaultDisplay;
          text = "cmd[update:1000] playerctl metadata --format \"{{ artist }} - {{ album }} - {{ title }}\"";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 18;
          font_family = "Mononoki Nerd Font";
          position = {
            x = 0;
            y = -50;
          };
          valign = "bottom";
        }
      ];
    };
  };
}
