{ config, lib, ... }:
let
  cfg = config.home_modules.swaync;

  catppuccinBase = builtins.readFile (config.catppuccin.sources.swaync + "/macchiato.css");

  enable = lib.mkEnableOption "swaync";
in
{
  options.home_modules.swaync = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    catppuccin.swaync.enable = false;

    services.swaync = {
      enable = true;

      style = ''
        ${catppuccinBase}

        /* The title widget sits flush against the mpris player below it;
           swaync gives neither a margin, so they read as one block. */
        .control-center .widget-title {
          margin-bottom: 14px;
        }

        /* Catppuccin renders every close (X) as a solid red square, which reads
           as a destructive action on notifications that are merely dismissable.
           A filled surface chip keeps it legible against the notification
           background and saves the red for the hover state. */
        .notification-background .close-button {
          background-color: #494d64;
          color: #cad3f5;
          box-shadow: inset 0 0 0 1px #5b6078;
          border-radius: 8px;
          padding: 2px 6px;
          margin: 6px;
          min-width: 22px;
          min-height: 22px;
          transition: background-color 180ms ease,
                      color 180ms ease,
                      box-shadow 180ms ease;
        }

        .notification-background .close-button:hover {
          background-color: #ed8796;
          color: #24273a;
          box-shadow: inset 0 0 0 1px #ed8796;
        }

        .notification-background .close-button:active {
          background-color: #ee99a0;
          color: #24273a;
        }

        .notification-group-close-all-button,
        .notification-group-collapse-button {
          color: #cad3f5;
          background-color: #494d64;
          box-shadow: inset 0 0 0 1px #5b6078;
          border-radius: 8px;
          padding: 4px 10px;
          margin: 4px;
          min-width: 28px;
          min-height: 24px;
          transition: background-color 180ms ease,
                      color 180ms ease,
                      box-shadow 180ms ease;
        }

        .notification-group-close-all-button:hover,
        .notification-group-collapse-button:hover {
          background-color: #c6a0f6;
          color: #24273a;
          box-shadow: inset 0 0 0 1px #c6a0f6;
        }

        .notification-group-close-all-button:active,
        .notification-group-collapse-button:active {
          background-color: #b7bdf8;
          color: #24273a;
        }
      '';

      settings = {
        positionX = "right";
        positionY = "top";

        control-center-positionX = "right";
        control-center-positionY = "top";
        control-center-margin-top = 8;
        control-center-margin-right = 8;
        control-center-margin-bottom = 8;
        control-center-width = 420;
        control-center-height = 720;

        notification-window-width = 400;
        notification-icon-size = 48;
        notification-body-image-height = 120;
        notification-body-image-width = 200;

        timeout = 6;
        timeout-low = 4;
        timeout-critical = 0;

        transition-time = 180;

        notification-2fa-action = true;
        notification-inline-replies = true;
        hide-on-clear = true;
        hide-on-action = true;
        keyboard-shortcuts = true;

        widgets = [
          "title"
          "mpris"
          "buttons-grid"
          "volume"
          "backlight"
          "dnd"
          "label#notif-label"
          "notifications"
        ];

        widget-config = {
          title = {
            text = "Notifications";
            clear-all-button = true;
            button-text = "Clear all";
          };

          mpris = {
            image-size = 80;
            image-radius = 10;
          };

          "buttons-grid" = {
            actions = [
              {
                label = "󰍁";
                command = "hyprlock";
              }
              {
                label = "󰤄";
                command = "systemctl suspend";
              }
              {
                label = "󰜉";
                command = "systemctl reboot";
              }
              {
                label = "󰐥";
                command = "systemctl poweroff";
              }
              {
                label = "󰍃";
                command = "hyprctl dispatch exit";
              }
              {
                label = "󰹑";
                command = "grim -g \"$(slurp)\" - | wl-copy";
              }
            ];
          };

          volume = {
            label = "󰕾";
            show-per-app = true;
          };

          backlight = {
            label = "󰃞";
            device = "amdgpu_bl1";
          };

          dnd = {
            text = "Do not disturb";
          };

          "label#notif-label" = {
            max-lines = 1;
            text = "Notifications";
          };
        };
      };
    };
  };
}
