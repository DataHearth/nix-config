{
  config,
  lib,
  ...
}:
let
  cfg = config.home_modules.hyprland;
  saveLocation = "${config.home.homeDirectory}/Pictures/Screenshots";
in
{
  config = lib.mkIf cfg.enable {
    programs.hyprshot = {
      enable = true;
      inherit saveLocation;
    };

    home_modules.hyprland.additional_envs = [
      "HYPRSHOT_DIR,${saveLocation}"
    ];
  };
}
