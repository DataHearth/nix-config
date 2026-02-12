{
  lib,
  config,
  ...
}:
let
  cfg = config.home_modules.jujutsu;
in
{
  options.home_modules.jujutsu = {
    enable = lib.mkEnableOption "jujutsu VCS";

    user = {
      name = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "DataHearth";
        description = "User name for jujutsu commits";
      };
      email = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "dev@antoine-langlois.net";
        description = "User email for jujutsu commits";
      };
    };

    signingKey = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
      description = "GPG key email for signing commits";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.difftastic.jujutsu.enable = config.home_modules.git.difftastic.enable;

    programs.jujutsu = {
      enable = true;
      settings = {
        signing = lib.mkIf (cfg.signingKey != null) {
          behavior = "own";
          backend = "gpg";
          key = cfg.signingKey;
        };
        git.sign-on-push = cfg.signingKey != null;
        user = {
          name = cfg.user.name;
          email = cfg.user.email;
        };
      };
    };
  };
}
