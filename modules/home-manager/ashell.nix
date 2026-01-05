{ config, lib, ... }:
let
  cfg = config.home_modules.ashell;

  enable = lib.mkEnableOption "ashell";
in
{
  options.home_modules.ashell = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    programs.ashell = {
      enable = true;
      settings = {
        log_level = "info";

        modules = {
          left = [
            "AppLauncher"
            "Workspaces"
            "SystemInfo"
          ];
          center = [ "Clock" ];
          right = [
            [
              "Privacy"
              "KeyboardLayout"
              "CustomNotifications"
            ]
            [ "Settings" ]
          ];
        };

        workspaces = {
          visibility_mode = "MonitorSpecific";
        };

        settings = {
          shutdown_cmd = "shutdown now";
          suspend_cmd = "systemctl suspend";
          reboot_cmd = "systemctl reboot";
          logout_cmd = "loginctl kill-user $(whoami)";
        };

        keyboard_layout.labels = {
          French = "🇫🇷";
          "English (intl., with AltGr dead keys)" = "🇺🇸";
        };

        system_info = {
          indicators = [
            "Cpu"
            "Memory"
            "Temperature"
          ];
        };

        CustomModule = [
          {
            name = "CustomNotifications";
            icon = "";
            command = "swaync-client -t -sw";
            listen_cmd = "swaync-client -swb";
            icons."dnd.*" = "";
            alert = ".*notification";
          }
          {
            name = "AppLauncher";
            icon = "󱗼";
            command = "walker";
          }
        ];

        appearance = {
          primary_color = "#7aa2f7";
          success_color = "#9ece6a";
          text_color = "#a9b1d6";
          workspace_colors = [
            "#7aa2f7"
            "#9ece6a"
          ];

          danger_color = {
            base = "#f7768e";
            weak = "#e0af68";
          };

          background_color = {
            base = "#1a1b26";
            weak = "#24273a";
            strong = "#414868";
          };

          secondary_color = {
            base = "#0c0d14";
          };
        };
      };
    };
  };
}
