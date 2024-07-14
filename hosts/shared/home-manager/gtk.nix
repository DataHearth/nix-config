{ pkgs, ... }: {
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
    theme = {
      name = "Adwaita";
      package = pkgs.gnome-themes-extra;
    };
  };
}
