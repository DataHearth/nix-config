{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.hyprland;
  saveLocation = "${config.home.homeDirectory}/Pictures/Screenshots";
  retentionDays = 30;

  screenshot-prune = pkgs.writeShellScript "screenshot-prune" ''
    dir=${lib.escapeShellArg saveLocation}
    [ -d "$dir" ] || exit 0
    ${pkgs.findutils}/bin/find "$dir" -mindepth 1 -type f -mtime +${toString retentionDays} -delete
  '';
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

    systemd.user.services.screenshot-prune = {
      Unit.Description = "Delete screenshots older than ${toString retentionDays} days";
      Service = {
        Type = "oneshot";
        ExecStart = toString screenshot-prune;
      };
    };

    systemd.user.timers.screenshot-prune = {
      Unit.Description = "Daily screenshot cleanup";
      Timer = {
        OnCalendar = "daily";
        # The laptop is rarely up at the timer's wall-clock slot, so without
        # Persistent the prune would almost never fire.
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
