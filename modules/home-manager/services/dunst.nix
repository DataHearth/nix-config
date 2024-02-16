{ pkgs, ... }:
{
  services.dunst = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus";
    };
    settings = {
      global = {
        monitor = 0;
        width = 300;
        height = 300;
        offset = "10x50";
        separator_height = 1;
        horizontal_padding = 10;
        frame_width = 0;
        frame_color = "#282a36";
        idle_threshold = 120;
        layer = "overlay";
        font = "FiraCode Nerd Font 12";
        format = "%s %p\n%b";
        alignment = "left";
        markup = "full";
        min_icon_size = 0;
        max_icon_size = 64;
        browser = "${pkgs.firefox}/bin/firefox --new-tab";
        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };
      urgency_low = {
        background = "#282a36";
        foreground = "#6272a4";
        timeout = 10;
      };
      urgency_normal = {
        background = "#282a36";
        foreground = "#bd93f9";
        timeout = 10;
      };
      urgency_critical = {
        background = "#ff5555";
        foreground = "#f8f8f2";
        frame_color = "#ff5555";
        timeout = 0;
      };
    };
  };
}