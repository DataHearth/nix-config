{ pkgs, ... }: {
  global = {
    monitor = 0;
    follow = "none";
    width = 300;
    height = 300;
    origin = "top-right";
    offset = "20x20";
    scale = 0;
    notification_limit = 20;
    progress_bar = true;
    progress_bar_height = 10;
    progress_bar_frame_width = 0;
    progress_bar_min_width = 125;
    progress_bar_max_width = 250;
    progress_bar_corner_radius = 4;
    icon_corner_radius = 5;
    indicate_hidden = true;
    transparency = 10;
    separator_height = 2;
    padding = 8;
    horizontal_padding = 8;
    text_icon_padding = 10;
    frame_width = 3;
    gap_size = 5;
    separator_color = "auto";
    sort = true;
    font = "Mononoki Nerd Font 8";
    line_height = 3;
    markup = "full";
    format = ''
      󰟪 %a
      <b>󰋑 %s</b>
      %b'';
    alignment = "left";
    vertical_alignment = "center";
    show_age_threshold = 60;
    ellipsize = "middle";
    ignore_newline = false;
    stack_duplicates = true;
    hide_duplicate_count = false;
    show_indicators = true;
    icon_theme = "Tela-circle-dracula";
    icon_position = "left";
    min_icon_size = 32;
    max_icon_size = 128;
    sticky_history = true;
    history_length = 20;
    browser = "${pkgs.firefox}/bin/firefox --new-tab";
    always_run_script = true;
    title = "Dunst";
    class = "Dunst";
    corner_radius = 10;
    ignore_dbusclose = false;
    force_xwayland = false;
    force_xinerama = false;
    mouse_left_click = "context, close_current";
    mouse_middle_click = "do_action, close_current";
    mouse_right_click = "close_all";
  };
  experimental = { per_monitor_dpi = false; };
  urgency_low = {
    background = "#22232A";
    foreground = "#E2DFD1";
    frame_color = "#262C48";
    timeout = 10;
  };
  urgency_normal = {
    background = "#4D5C78";
    foreground = "#E2DFD1";
    frame_color = "#622D28";
    timeout = 10;
  };
  urgency_critical = {
    background = "#f5e0dc";
    foreground = "#1e1e2e";
    frame_color = "#f38ba8";
    timeout = 0;
  };
  "Type-1" = {
    summary = "t1";
    format = "<b>%a</b>";
  };
  "Type-2" = {
    summary = "t2";
    format = ''
      <span size="250%">%a</span>
      %b'';
  };
}
