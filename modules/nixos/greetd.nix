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
      settings = {
        default_session = {
          command = builtins.concatStringsSep " " [
            "${pkgs.tuigreet}/bin/tuigreet"
            "--time"
            "--time-format '%A, %B %d %Y  %H:%M'"
            "--greeting 'Welcome back'"
            "--remember"
            "--remember-session"
            "--sessions ${sessionData}/share/wayland-sessions"
            "--asterisks"
            "--asterisks-char '•'"
            "--width 80"
            "--window-padding 2"
            "--container-padding 2"
            "--prompt-padding 1"
            "--theme 'border=#8aadf4;text=#cad3f5;time=#c6a0f6;container=#24273a;button=#a6da95;prompt=#f5bde6;action=#f5a97f;input=#f4dbd6'"
          ];
          user = config.users.users.datahearth.name;
        };
      };
    };

    programs.regreet = lib.mkIf (cfg.greeter == "regreet") {
      enable = true;
    };
  };
}
