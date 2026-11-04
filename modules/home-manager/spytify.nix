{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.home_modules.spytify;
  toml = pkgs.formats.toml { };
  targetEnv = lib.filterAttrs (_: v: v != null && v != "") {
    SPYTIFY_TARGET_PROCESS = lib.concatStringsSep "," cfg.target.process;
    SPYTIFY_TARGET_MPRIS = cfg.target.mpris;
    SPYTIFY_TARGET_LAUNCH = cfg.target.launch;
  };
in
{
  options.home_modules.spytify = {
    enable = lib.mkEnableOption "Spytify, a per-application audio recorder";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.spytify;
      defaultText = lib.literalExpression "pkgs.spytify";
      description = "The Spytify package to use.";
    };

    target = {
      process = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ ".spotify-wrapped" ];
        description = ''
          Process names of the player to record, matched against PipeWire's
          application.process.binary / application.name and /proc comm.
        '';
      };

      mpris = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "org.mpris.MediaPlayer2.spotify";
        description = "Full MPRIS D-Bus name; derived from the first process name when null.";
      };

      launch = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Shell command the recorder runs to start the player.";
      };
    };

    settings = lib.mkOption {
      inherit (toml) type;
      default = { };
      example = {
        output.dir = "~/Music";
      };
      description = "Contents of ~/.config/spytify/config.toml (keys as `spytify-cli get` lists them).";
    };
  };

  # force: the app replaces both files when its Settings page saves
  # (config.toml by atomic rename, .env by rewriting it), which would leave
  # a regular file where the symlink was and make the next switch refuse to
  # clobber it. With force the declared values come back on every switch and
  # in-app edits last until then.
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "spytify/.env" = lib.mkIf (targetEnv != { }) {
        force = true;
        text = lib.concatStrings (lib.mapAttrsToList (k: v: "${k}=${builtins.toJSON v}\n") targetEnv);
      };
      "spytify/config.toml" = lib.mkIf (cfg.settings != { }) {
        force = true;
        source = toml.generate "spytify-config.toml" cfg.settings;
      };
    };
  };
}
