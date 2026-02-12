{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  cfg = config.home_modules.niri;
  isStandalone = (options.programs ? niri) && (options.programs.niri ? enable);

  terminal = "${config.programs.alacritty.package}/bin/alacritty";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
in
{
  options.home_modules.niri = {
    enable = lib.mkEnableOption "niri scrollable-tiling Wayland compositor";
    package = lib.mkPackageOption pkgs "niri" { };
  };

  config = lib.mkIf cfg.enable {
    programs.niri = lib.optionalAttrs isStandalone {
      enable = true;
      package = cfg.package;
    } // {
      settings = {
        input = {
          keyboard.xkb = {
            layout = "fr,us";
            variant = ",altgr-intl";
            model = ",pc105";
            options = "grp:alt_space_toggle";
          };
          touchpad = {
            tap = true;
            natural-scroll = false;
          };
          mouse.accel-profile = "flat";
          focus-follows-mouse.enable = true;
        };

        layout = {
          gaps = 8;
          border = {
            enable = true;
            width = 2;
            active.color = "#33ccff";
            inactive.color = "#595959";
          };
          focus-ring.enable = false;
          center-focused-column = "on-overflow";
          default-column-width.proportion = 0.5;
        };

        environment = {
          XCURSOR_SIZE = "24";
        };

        binds =
          with config.lib.niri.actions;
          let
            mainMod = "Mod";
          in
          {
            # ── Applications ──────────────────────────────
            "${mainMod}+Return" = {
              action = spawn terminal;
              repeat = false;
            };
            "${mainMod}+Space" = {
              action = spawn "${lib.getExe config.services.walker.package}";
              repeat = false;
            };
            "${mainMod}+E" = {
              action = spawn "${pkgs.nautilus}/bin/nautilus";
              repeat = false;
            };
            "${mainMod}+Q" = {
              action = close-window;
            };

            # ── Column / window focus ─────────────────────
            "${mainMod}+Left" = {
              action = focus-column-left;
            };
            "${mainMod}+Right" = {
              action = focus-column-right;
            };
            "${mainMod}+Up" = {
              action = focus-window-up;
            };
            "${mainMod}+Down" = {
              action = focus-window-down;
            };

            # ── Move column / window ──────────────────────
            "${mainMod}+Shift+Left" = {
              action = move-column-left;
            };
            "${mainMod}+Shift+Right" = {
              action = move-column-right;
            };
            "${mainMod}+Shift+Up" = {
              action = move-window-up;
            };
            "${mainMod}+Shift+Down" = {
              action = move-window-down;
            };

            # ── Column sizing ─────────────────────────────
            "${mainMod}+R" = {
              action = switch-preset-column-width;
            };
            "${mainMod}+Equal" = {
              action = set-column-width "+10%";
            };
            "${mainMod}+Minus" = {
              action = set-column-width "-10%";
            };
            "${mainMod}+Shift+Equal" = {
              action = set-window-height "+10%";
            };
            "${mainMod}+Shift+Minus" = {
              action = set-window-height "-10%";
            };

            # ── Layout ────────────────────────────────────
            "${mainMod}+F" = {
              action = fullscreen-window;
            };
            "${mainMod}+V" = {
              action = toggle-window-floating;
            };
            "${mainMod}+C" = {
              action = center-column;
            };

            # ── Workspaces ────────────────────────────────
            "${mainMod}+1" = {
              action = focus-workspace 1;
            };
            "${mainMod}+2" = {
              action = focus-workspace 2;
            };
            "${mainMod}+3" = {
              action = focus-workspace 3;
            };
            "${mainMod}+4" = {
              action = focus-workspace 4;
            };
            "${mainMod}+5" = {
              action = focus-workspace 5;
            };
            "${mainMod}+6" = {
              action = focus-workspace 6;
            };
            "${mainMod}+7" = {
              action = focus-workspace 7;
            };
            "${mainMod}+8" = {
              action = focus-workspace 8;
            };
            "${mainMod}+9" = {
              action = focus-workspace 9;
            };

            "${mainMod}+Shift+1".action.move-column-to-workspace = 1;
            "${mainMod}+Shift+2".action.move-column-to-workspace = 2;
            "${mainMod}+Shift+3".action.move-column-to-workspace = 3;
            "${mainMod}+Shift+4".action.move-column-to-workspace = 4;
            "${mainMod}+Shift+5".action.move-column-to-workspace = 5;
            "${mainMod}+Shift+6".action.move-column-to-workspace = 6;
            "${mainMod}+Shift+7".action.move-column-to-workspace = 7;
            "${mainMod}+Shift+8".action.move-column-to-workspace = 8;
            "${mainMod}+Shift+9".action.move-column-to-workspace = 9;

            "${mainMod}+Page_Down" = {
              action = focus-workspace-down;
            };
            "${mainMod}+Page_Up" = {
              action = focus-workspace-up;
            };

            # ── Screenshots ───────────────────────────────
            "Print".action.screenshot = { };
            "Ctrl+Print".action.screenshot-screen = { };
            "Alt+Print".action.screenshot-window = { };

            # ── Session ───────────────────────────────────
            "${mainMod}+Shift+E" = {
              action = quit;
            };
            "${mainMod}+S" = {
              action = spawn "systemctl" "suspend";
              repeat = false;
            };
            "${mainMod}+Shift+S" = {
              action = spawn "systemctl" "poweroff";
              repeat = false;
            };
            "${mainMod}+Shift+R" = {
              action = spawn "systemctl" "reboot";
              repeat = false;
            };
            "${mainMod}+L" = {
              action = spawn "loginctl" "lock-session";
              repeat = false;
            };

            # ── Media keys ────────────────────────────────
            "XF86AudioRaiseVolume" = {
              action = spawn wpctl "set-volume" "-l" "1" "@DEFAULT_AUDIO_SINK@" "5%+";
            };
            "XF86AudioLowerVolume" = {
              action = spawn wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";
            };
            "XF86AudioMute" = {
              action = spawn wpctl "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
            };
            "XF86AudioMicMute" = {
              action = spawn wpctl "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle";
            };
            "XF86MonBrightnessUp" = {
              action = spawn brightnessctl "-e4" "-n2" "set" "5%+";
            };
            "XF86MonBrightnessDown" = {
              action = spawn brightnessctl "-e4" "-n2" "set" "5%-";
            };
            "XF86AudioNext" = {
              action = spawn playerctl "next";
            };
            "XF86AudioPrev" = {
              action = spawn playerctl "previous";
            };
            "XF86AudioPlay" = {
              action = spawn playerctl "play-pause";
            };
            "XF86AudioPause" = {
              action = spawn playerctl "play-pause";
            };
          };
      };
    };

    # Only needed in standalone Home Manager mode (non-NixOS)
    xdg.configFile."systemd/user/niri.service" = lib.mkIf isStandalone {
      source = "${cfg.package}/share/systemd/user/niri.service";
    };
    xdg.configFile."systemd/user/niri-shutdown.target" = lib.mkIf isStandalone {
      source = "${cfg.package}/share/systemd/user/niri-shutdown.target";
    };

    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    programs.dank-material-shell.enable = lib.mkDefault true;

    services.cliphist.enable = lib.mkDefault true;

    home_modules = {
      walker.enable = lib.mkDefault true;
      swaync.enable = lib.mkDefault true;
    };
  };
}
