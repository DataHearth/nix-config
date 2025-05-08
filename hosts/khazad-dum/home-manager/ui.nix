{ pkgs, ... }:
let
  theme_name = "WhiteSur-Dark";
  cursor_theme = "WhiteSur-cursors";
  cursor_size = 32;
  cursor_pkg = pkgs.whitesur-cursors;
in
{
  home = {
    sessionVariables.GTK_THEME = theme_name;

    pointerCursor = {
      gtk.enable = true;
      package = cursor_pkg;
      name = cursor_theme;
      size = cursor_size;
    };
  };

  dconf = {
    enable = true;

    settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = theme_name;
    };
  };

  gtk = {
    enable = true;

    iconTheme = {
      name = "WhiteSur";
      package = pkgs.whitesur-icon-theme;
    };

    theme = {
      name = theme_name;
      package = pkgs.whitesur-gtk-theme;
    };

    cursorTheme = {
      name = cursor_theme;
      package = cursor_pkg;
      size = cursor_size;
    };
  };
}
