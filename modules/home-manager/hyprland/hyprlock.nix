{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.hyprland;

  macchiatoTheme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/hyprland/c388ac55563ddeea0afe9df79d4bfff0096b146b/themes/macchiato.conf";
    hash = "sha256-iA3WePp1L381pxnl145K5P4cimbisX3YJQ8I4XTJDrk=";
  };

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
      settings = {
        source = toString macchiatoTheme;
        "$accent" = "$mauve";
        "$accentAlpha" = "$mauveAlpha";
        "$font" = "Mononoki Nerd Font";

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
            color = "$base";
          }
        ];

        input-field = [
          {
            monitor = if cfg.default_display != null then cfg.default_display else "";
            size = "300, 60";
            outline_thickness = 4;
            dots_size = 0.2;
            dots_spacing = 0.2;
            dots_center = true;
            outer_color = "$accent";
            inner_color = "$surface0";
            font_color = "$text";
            fade_on_empty = false;
            placeholder_text = ''<span foreground="##$textAlpha"><i>󰌾 Logged in as </i><span foreground="##$accentAlpha">$USER</span></span>'';
            hide_input = false;
            check_color = "$accent";
            fail_color = "$red";
            fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
            capslock_color = "$yellow";
            position = "0, -47";
            halign = "center";
            valign = "center";
          }
        ];

        label =
          let
            monitor = if cfg.default_display != null then cfg.default_display else "";
          in
          [
            # TIME — top right
            {
              inherit monitor;
              text = "$TIME";
              font_family = "$font";
              color = "$text";
              font_size = 90;
              position = "-30, 0";
              valign = "top";
              halign = "right";
            }
            # DATE — below time, top right
            {
              inherit monitor;
              text = ''cmd[update:43200000] date +"%A, %d %B %Y"'';
              font_family = "$font";
              color = "$text";
              font_size = 25;
              position = "-30, -150";
              valign = "top";
              halign = "right";
            }
            # LAYOUT — top left
            {
              inherit monitor;
              text = "Layout: $LAYOUT";
              font_family = "$font";
              color = "$text";
              font_size = 25;
              position = "30, -30";
              valign = "top";
              halign = "left";
            }
            # FINGERPRINT
            {
              inherit monitor;
              text = "$FPRINTPROMPT";
              font_family = "$font";
              color = "$text";
              font_size = 14;
              position = "0, -107";
              halign = "center";
              valign = "center";
            }
            # MEDIA — bottom center
            {
              inherit monitor;
              text = ''cmd[update:1000] ${pkgs.playerctl}/bin/playerctl metadata --format "{{ artist }} - {{ album }} - {{ title }}"'';
              font_family = "$font";
              color = "$subtext0";
              font_size = 18;
              position = "0, -50";
              valign = "bottom";
              halign = "center";
            }
          ];
      };
    };
  };
}
