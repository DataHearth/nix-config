{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos_modules.greetd;

  enable = lib.mkEnableOption "greetd display manager";
  greeter = lib.mkOption {
    type = lib.types.enum [
      "tuigreet"
      "regreet"
    ];
    default = "tuigreet";
    description = "Which greeter to use with greetd";
  };

  sessionData = config.services.displayManager.sessionData.desktops;
in
{
  options.nixos_modules.greetd = {
    inherit enable greeter;
  };

  config = lib.mkIf cfg.enable {
    security.pam.services.greetd.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;

    services.greetd = lib.mkIf (cfg.greeter == "tuigreet") {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember-session --sessions ${sessionData}/share/wayland-sessions";
        user = config.users.users.datahearth.name;
      };
    };

    programs.regreet = lib.mkIf (cfg.greeter == "regreet") {
      enable = true;
    };
  };
}
