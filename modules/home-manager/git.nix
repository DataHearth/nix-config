{
  config,
  lib,
  ...
}:
let
  cfg = config.home_modules.git;
in
{
  options.home_modules.git = {
    enable = lib.mkEnableOption "git";

    signingKey = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      description = "The GPG key to use for signing commits";
      example = "A12925470298BFEE7EE092B3946E2D0C410C7B3D";
      default = null;
    };

    user = {
      name = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "DataHearth";
        description = "Git user name";
      };
      email = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "dev@antoine-langlois.net";
        description = "Git user email";
      };
    };

    difftastic.enable = lib.mkEnableOption "difftastic structural diff";

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      description = "Extra git configuration";
      default = { };
    };

    extraAliases = lib.mkOption {
      type = lib.types.attrs;
      description = "Extra git aliases";
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      lfs.enable = true;
      signing = lib.mkIf (cfg.signingKey != null) {
        signByDefault = true;
        key = cfg.signingKey;
      };
      settings = {
        alias = {
          co = "checkout";
          p = "push";
          c = "commit";
          s = "status";
          pu = "pull";
          logs = "log --graph --oneline";
          update-remote = "remote update origin --prune";
          tags = "git tag --list";
        } // cfg.extraAliases;
        user = {
          name = cfg.user.name;
          email = cfg.user.email;
        };
        init.defaultBranch = "main";
      } // cfg.extraConfig;
    };

    programs.difftastic = lib.mkIf cfg.difftastic.enable {
      enable = true;
      git.enable = true;
    };
  };
}
