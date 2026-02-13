{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.hyprland;

  enable = lib.mkEnableOption "Hyprland window manager";
  exec_once = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Additional programs to execute once on startup";
  };
  additional_envs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Additional environment variables in format 'VAR,value'";
  };
  window_rules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "window rules";
  };
  package = lib.mkPackageOption pkgs "hyprland" { };
  display_manager = lib.mkEnableOption "display_manager";
  status_bar = lib.mkOption {
    type = lib.types.enum [
      "ashell"
      "waybar"
      "none"
    ];
    default = "ashell";
    description = "Status bar to use";
  };

  terminal = "${config.programs.alacritty.package}/bin/alacritty";
  mainMod = "SUPER";
in
{
  options.home_modules.hyprland = {
    inherit
      enable
      window_rules
      exec_once
      additional_envs
      package
      display_manager
      status_bar
      ;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ (lib.mkIf cfg.display_manager nwg-displays) ];

    programs.elephant = {
      enable = true;
      installService = true;
    };

    services.cliphist.enable = lib.mkDefault true;

    home_modules = {
      walker.enable = lib.mkDefault true;
      swaync.enable = lib.mkDefault true;
      hyprland.awww.enable = lib.mkDefault true;
      waybar.enable = cfg.status_bar == "waybar";
      ashell.enable = cfg.status_bar == "ashell";
    };

    wayland.windowManager.hyprland = {
      enable = true;
      package = cfg.package;

      settings = {
        source = lib.mkIf cfg.display_manager [
          "~/.config/hypr/monitors.conf"
          "~/.config/hypr/workspaces.conf"
        ];

        ecosystem.no_update_news = true;

        monitor = ",preferred,auto,auto";

        exec-once = [
          "hyprctl hyprpaper"
          terminal
        ]
        ++ lib.optional (cfg.status_bar == "ashell") "ashell"
        ++ lib.optional (cfg.status_bar == "waybar") "waybar"
        ++ cfg.exec_once;

        env = [
          "XCURSOR_SIZE,24"
          "HYPRCURSOR_SIZE,24"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
        ]
        ++ cfg.additional_envs;

        general = {
          gaps_in = 5;
          gaps_out = 5;
          border_size = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        decoration = {
          rounding = 2;
          rounding_power = 2;
          active_opacity = 1.0;
          inactive_opacity = 1.0;

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };

        animations = {
          enabled = "yes, please :)";

          bezier = [
            "easeOutQuint, 0.23, 1, 0.32, 1"
            "easeInOutCubic, 0.65, 0.05, 0.36, 1"
            "linear, 0, 0, 1, 1"
            "almostLinear, 0.5, 0.5, 0.75, 1"
            "quick, 0.15, 0, 0.1, 1"
          ];

          animation = [
            "global, 1, 10, default"
            "border, 1, 5.39, easeOutQuint"
            "windows, 1, 4.79, easeOutQuint"
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
            "windowsOut, 1, 1.49, linear, popin 87%"
            "fadeIn, 1, 1.73, almostLinear"
            "fadeOut, 1, 1.46, almostLinear"
            "fade, 1, 3.03, quick"
            "layers, 1, 3.81, easeOutQuint"
            "layersIn, 1, 4, easeOutQuint, fade"
            "layersOut, 1, 1.5, linear, fade"
            "fadeLayersIn, 1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces, 1, 1.94, almostLinear, fade"
            "workspacesIn, 1, 1.21, almostLinear, fade"
            "workspacesOut, 1, 1.94, almostLinear, fade"
            "zoomFactor, 1, 7, quick"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master.new_status = "master";

        misc = {
          force_default_wallpaper = -1;
          disable_hyprland_logo = false;
        };

        input = {
          kb_layout = "fr,us";
          kb_variant = ",altgr-intl";
          kb_model = ",pc105";
          kb_options = "grp:alt_space_toggle";
          kb_rules = "";
          resolve_binds_by_sym = 1;
          follow_mouse = 1;
          sensitivity = 0;

          touchpad.natural_scroll = false;
        };

        gesture = "3, horizontal, workspace";

        device = {
          name = "epic-mouse-v1";
          sensitivity = -0.5;
        };

        bind =
          let
            hyprshot_bin = "${pkgs.hyprshot}/bin/hyprshot";
          in
          [
            "${mainMod}, Return, exec, ${terminal}"
            "${mainMod}, Q, killactive,"
            "${mainMod}, M, exit,"
            "${mainMod}, E, exec, ${pkgs.nautilus}/bin/nautilus"
            "${mainMod}, V, togglefloating,"
            "${mainMod}, C, exec, cliphist list | walker --dmenu | cliphist decode | wl-copy"
            "${mainMod}, Space, exec, ${config.services.walker.package}/bin/walker"
            "${mainMod}, P, pseudo,"
            "${mainMod}, J, togglesplit,"

            "${mainMod}, left, movefocus, l"
            "${mainMod}, right, movefocus, r"
            "${mainMod}, up, movefocus, u"
            "${mainMod}, down, movefocus, d"

            "${mainMod} SHIFT, left, movewindow, l"
            "${mainMod} SHIFT, right, movewindow, r"
            "${mainMod} SHIFT, up, movewindow, u"
            "${mainMod} SHIFT, down, movewindow, d"

            "${mainMod}, code:10, workspace, 1"
            "${mainMod}, code:11, workspace, 2"
            "${mainMod}, code:12, workspace, 3"
            "${mainMod}, code:13, workspace, 4"
            "${mainMod}, code:14, workspace, 5"
            "${mainMod}, code:15, workspace, 6"
            "${mainMod}, code:16, workspace, 7"
            "${mainMod}, code:17, workspace, 8"
            "${mainMod}, code:18, workspace, 9"
            "${mainMod}, code:19, workspace, 10"

            "${mainMod} SHIFT, code:10, movetoworkspace, 1"
            "${mainMod} SHIFT, code:11, movetoworkspace, 2"
            "${mainMod} SHIFT, code:12, movetoworkspace, 3"
            "${mainMod} SHIFT, code:13, movetoworkspace, 4"
            "${mainMod} SHIFT, code:14, movetoworkspace, 5"
            "${mainMod} SHIFT, code:15, movetoworkspace, 6"
            "${mainMod} SHIFT, code:16, movetoworkspace, 7"
            "${mainMod} SHIFT, code:17, movetoworkspace, 8"
            "${mainMod} SHIFT, code:18, movetoworkspace, 9"
            "${mainMod} SHIFT, code:19, movetoworkspace, 10"

            "${mainMod}, mouse_down, workspace, e+1"
            "${mainMod}, mouse_up, workspace, e-1"

            "${mainMod}, F, fullscreen"
            "${mainMod}, L, exec, loginctl lock-session"
            "${mainMod}, I, exec, ${lib.getExe config.home_modules.hyprland.hypridle.toggleScript}"
            "${mainMod}, S, exec, systemctl suspend"
            "${mainMod} SHIFT, S, exec, systemctl poweroff"
            "${mainMod} SHIFT, R, exec, systemctl reboot"

            "${mainMod}, PRINT, exec, ${hyprshot_bin} -m window"
            ", PRINT, exec, ${hyprshot_bin} -m output"
            "${mainMod} SHIFT, PRINT, exec, ${hyprshot_bin} -m region"
          ];

        bindel =
          let
            wpctl_bin = "${pkgs.wireplumber}/bin/wpctl";
            brightnessctl_bin = "${pkgs.brightnessctl}/bin/brightnessctl";
          in
          [
            ",XF86AudioRaiseVolume, exec, ${wpctl_bin} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
            ",XF86AudioLowerVolume, exec, ${wpctl_bin} set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ",XF86AudioMute, exec, ${wpctl_bin} set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ",XF86AudioMicMute, exec, ${wpctl_bin} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
            ",XF86MonBrightnessUp, exec, ${brightnessctl_bin} -e4 -n2 set 5%+"
            ",XF86MonBrightnessDown, exec, ${brightnessctl_bin} -e4 -n2 set 5%-"
          ];

        bindl =
          let
            playerctl_bin = "${pkgs.playerctl}/bin/playerctl";
          in
          [
            ", XF86AudioNext, exec, ${playerctl_bin} next"
            ", XF86AudioPause, exec, ${playerctl_bin} play-pause"
            ", XF86AudioPlay, exec, ${playerctl_bin} play-pause"
            ", XF86AudioPrev, exec, ${playerctl_bin} previous"
          ];

        bindm = [
          "${mainMod}, mouse:272, movewindow"
          "${mainMod}, mouse:273, resizewindow"
        ];

        windowrule = [
          "suppress_event maximize, match:class .*"
          "no_focus 1, match:class ^$, match:title ^$, match:xwayland 1, match:float 1, match:fullscreen 0, match:pin 0"
        ]
        ++ cfg.window_rules;
      };
    };
  };
}
