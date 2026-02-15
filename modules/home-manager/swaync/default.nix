{ config, lib, pkgs, ... }:
let
  cfg = config.home_modules.swaync;

  macchiatoStyle = pkgs.fetchurl {
    url = "https://github.com/catppuccin/swaync/releases/download/v1.0.1/catppuccin-macchiato.css";
    hash = "sha256-jN7oHf075g463+pPtiTJl3OTXMQjQ+O+OS8L4cCTipI=";
  };

  enable = lib.mkEnableOption "swaync";
in
{
  options.home_modules.swaync = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    services.swaync = {
      enable = true;
      style = macchiatoStyle;

      settings = {
        # Position like macOS - top right
        positionX = "right";
        positionY = "top";

        # Control center positioning
        control-center-positionX = "right";
        control-center-positionY = "top";
        control-center-margin-top = 8;
        control-center-margin-right = 8;
        control-center-margin-bottom = 8;
        control-center-width = 380;

        # Notification behavior
        notification-window-width = 380;
        notification-icon-size = 64;
        notification-body-image-height = 100;
        notification-body-image-width = 100;

        # Timeouts (in seconds)
        timeout = 6;
        timeout-low = 4;
        timeout-critical = 0;

        # Animations
        transition-time = 200;

        # Grouping like macOS
        notification-2fa-action = true;
        notification-inline-replies = true;

        # Control center widgets
        widgets = [
          "title"
          "dnd"
          "notifications"
          "mpris"
        ];
        widget-config = {
          title = {
            text = "Notifications";
            clear-all-button = true;
            button-text = "Clear All";
          };
          dnd = {
            text = "Do Not Disturb";
          };
          mpris = {
            image-size = 96;
            image-radius = 8;
          };
        };
      };
    };
  };
}
