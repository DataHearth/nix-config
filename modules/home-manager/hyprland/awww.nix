{
  config,
  lib,
  pkgs,
  awww,
  ...
}:
let
  cfg = config.home_modules.hyprland;

  enable = lib.mkEnableOption "awww wallpaper daemon" // {
    default = cfg.enable;
  };
  wallpaper_path = lib.mkOption {
    type = lib.types.either lib.types.nonEmptyStr lib.types.path;
    default = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/refs/heads/master/wallpapers/nix-wallpaper-binary-blue.png";
      hash = "sha256-oVIRSgool/CsduGingDr0FuJJIkGtfQHXYn0JBI2eho=";
    };
    description = "Path to wallpaper image for awww";
  };
  randomize = {
    enable = lib.mkEnableOption "random wallpaper rotation";

    directory = lib.mkOption {
      type = lib.types.path;
      default = "${config.home.homeDirectory}/Pictures/Wallpapers";
      description = "Directory containing wallpaper images";
    };

    interval = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Interval in seconds between wallpaper changes";
    };
  };

  system = pkgs.stdenv.hostPlatform.system;
  awwwPkg = awww.packages.${system}.awww;
  randomWallpaperScript = pkgs.writeShellScript "awww-random-wallpaper" ''
    dir="${cfg.awww.randomize.directory}"
    interval="${toString cfg.awww.randomize.interval}"

    while true; do
      img=$(${pkgs.fd}/bin/fd -t f -e png -e jpg -e jpeg -e gif -e webp . "$dir" | ${pkgs.coreutils}/bin/shuf -n 1)
      if [ -n "$img" ]; then
        ${awwwPkg}/bin/awww img "$img"
      fi

      ${pkgs.coreutils}/bin/sleep "$interval"
    done
  '';
in
{
  options.home_modules.hyprland.awww = {
    inherit enable wallpaper_path randomize;
  };

  config = lib.mkIf cfg.awww.enable {
    home.packages = [ awwwPkg ];

    wayland.windowManager.hyprland.settings.exec-once = [
      "${awwwPkg}/bin/awww-daemon"
    ]
    ++ (
      if cfg.awww.randomize.enable then
        [ "${randomWallpaperScript}" ]
      else
        [ "${awwwPkg}/bin/awww img ${toString cfg.awww.wallpaper_path}" ]
    );
  };
}
