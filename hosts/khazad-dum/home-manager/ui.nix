{ pkgs, ... }:
let
  cursor_theme = "volantes_cursors";
  cursor_size = 32;
  cursor_pkg = pkgs.volantes-cursors;
in
{
  home.pointerCursor = {
    gtk.enable = true;
    package = cursor_pkg;
    name = cursor_theme;
    size = cursor_size;
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "kora";
      package = pkgs.kora-icon-theme;
    };

    theme = {
      name = "Orchis";
      package = pkgs.orchis-theme;
    };

    cursorTheme = {
      name = cursor_theme;
      package = cursor_pkg;
      size = cursor_size;
    };
  };
}
