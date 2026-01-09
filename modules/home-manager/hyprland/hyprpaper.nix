{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.hyprland;

  wallpaper_path = lib.mkOption {
    type = lib.types.either lib.types.nonEmptyStr lib.types.path;
    default = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/refs/heads/master/wallpapers/nix-wallpaper-binary-blue.png";
      hash = "sha256-oVIRSgool/CsduGingDr0FuJJIkGtfQHXYn0JBI2eho=";
    };
    description = "Path to wallpaper image for hyprpaper";
  };
in
{
  options.home_modules.hyprland = {
    inherit wallpaper_path;
  };

  config = lib.mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.hyprpaper;
      settings.wallpaper = {
        monitor = "";
        path = toString cfg.wallpaper_path;
      };
    };
  };
}
