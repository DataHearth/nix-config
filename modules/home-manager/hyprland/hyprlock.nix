{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.hyprland;

  lock_wallpaper = lib.mkOption {
    type = lib.types.either lib.types.nonEmptyStr lib.types.path;
    default = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/refs/heads/master/wallpapers/nix-wallpaper-binary-black.png";
      hash = "sha256-mhSh0wz2ntH/kri3PF5ZrFykjjdQLhmlIlDDGFQIYWw=";
    };
    description = "Path to background image for lock screen";
  };

  default_display = lib.mkOption {
    type = lib.types.nullOr lib.types.nonEmptyStr;
    default = null;
    description = "Default display for hyprlock labels and input-fields";
  };
in
{
  options.home_modules.hyprland = {
    inherit
      lock_wallpaper
      default_display
      ;
  };

  config = lib.mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      # when on non-NixOS distribution, hyprlock must be installed outside of nix for correct polkit usage
      package = null;
      settings = {
        auth.fingerprint.enabled = true;

        general = {
          grace = 0;
          hide_cursor = true;
          ignore_empty_input = false;
        };

        background = [
          {
            path = toString cfg.lock_wallpaper;
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
            monitor = if cfg.default_display != null then cfg.default_display else "";
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

        label =
          let
            monitor = if cfg.default_display != null then cfg.default_display else "";
          in
          [
            {
              inherit monitor;
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
              inherit monitor;
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
              inherit monitor;
              text = ''cmd[update:1000] ${pkgs.playerctl}/bin/playerctl metadata --format "{{ artist }} - {{ album }} - {{ title }}"'';
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
      };
    };
  };
}
