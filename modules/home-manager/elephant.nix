{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.elephant;
  settingsFormat = pkgs.formats.toml { };
  defaultProviders = [
    "bluetooth"
    "bookmarks"
    "calc"
    "clipboard"
    "desktopapplications"
    "files"
    "menus"
    "providerlist"
    "runner"
    "snippets"
    "symbols"
    "todo"
    "unicode"
    "websearch"
    "windows"
  ];
in
{
  options.programs.elephant = {
    enable = lib.mkEnableOption "Elephant launcher backend";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.elephant;
      description = "The elephant package to use.";
    };

    providers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultProviders;
      description = "List of built-in providers to enable.";
    };

    installService = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Create a systemd service for elephant.";
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable debug logging for elephant service.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = settingsFormat.type; };
      default = { };
      description = "Elephant configuration (elephant.toml).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = lib.mkMerge [
      (lib.mkIf (cfg.settings != { }) {
        "elephant/elephant.toml".source = settingsFormat.generate "elephant.toml" cfg.settings;
      })

      (builtins.listToAttrs (
        map (
          provider:
          lib.nameValuePair "elephant/providers/${provider}.so" {
            source = "${cfg.package}/lib/elephant/providers/${provider}.so";
            force = true;
          }
        ) cfg.providers
      ))
    ];

    systemd.user.services.elephant = lib.mkIf cfg.installService {
      Unit = {
        Description = "Elephant launcher backend";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/elephant ${lib.optionalString cfg.debug "--debug"}";
        Restart = "on-failure";
        RestartSec = 1;
        ExecStopPost = "${pkgs.coreutils}/bin/rm -f /tmp/elephant.sock";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
