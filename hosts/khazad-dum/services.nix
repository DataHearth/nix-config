{ pkgs, ... }:
{
  services = {
    ssh-agent.enable = true;

    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-gnome3;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    };

    hyprpaper = {
      enable = true;
      settings =
        let
          wallpaper_path = "~/.local/share/backgrounds/2025-10-19-18-43-55-uwp36741.png";
        in
        {
          preload = wallpaper_path;
          wallpaper = ", ${wallpaper_path}";
        };
    };
  };
}
