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

        /* ── Stacked notification controls ──
           Targets the buttons rendered on a notification group:
           - close-all-button: clears the whole stack
           - collapse-button:  expands/collapses the stack
           Plus a subtler close (X) on each entry inside an opened stack. */
        .notification-group-close-all-button,
        .notification-group-collapse-button {
          color: #cad3f5;
          background-color: #363a4f;
          box-shadow: inset 0 0 0 1px #494d64;
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

        .notification-group:focus .notification-group-close-all-button,
        .notification-group:focus .notification-group-collapse-button {
          box-shadow: inset 0 0 0 1px #5b6078;
        }

        /* Individual close (X) on stacked notifications when the group is open.
           Catppuccin makes it a solid red square — soften it so it sits quietly
           until hovered, and matches the group buttons. */
        .control-center .notification-group .notification-background .close-button,
        .notification-group .notification-background .close-button {
          background-color: transparent;
          color: #a5adcb;
          box-shadow: inset 0 0 0 1px #494d64;
          border-radius: 8px;
          padding: 2px 6px;
          margin: 6px;
          min-width: 22px;
          min-height: 22px;
          transition: background-color 180ms ease,
                      color 180ms ease,
                      box-shadow 180ms ease;
        }

        .control-center .notification-group .notification-background .close-button:hover,
        .notification-group .notification-background .close-button:hover {
          background-color: #ed8796;
          color: #24273a;
          box-shadow: inset 0 0 0 1px #ed8796;
        }

        .control-center .notification-group .notification-background .close-button:active,
        .notification-group .notification-background .close-button:active {
          background-color: #ee99a0;
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
