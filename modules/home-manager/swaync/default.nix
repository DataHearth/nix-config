{ config, lib, ... }:
let
  cfg = config.home_modules.swaync;

  enable = lib.mkEnableOption "swaync";
in
{
  options.home_modules.swaync = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    services.swaync = {
      enable = true;
      style = ./style.css;

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
        notification-icon-size = 48;
        notification-body-image-height = 160;
        notification-body-image-width = 200;

        # Timeouts (in ms)
        timeout = 6000;
        timeout-low = 4000;
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
