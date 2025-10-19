{ config, lib, ... }:
let
  cfg = config.home_modules.git;

  enable = lib.mkEnableOption "git";
  signingKey = lib.mkOption {
    type = lib.types.nullOr lib.types.nonEmptyStr;
    description = "The GPG key to use for signing commits";
    example = "A12925470298BFEE7EE092B3946E2D0C410C7B3D";
    default = null;
  };
  user = lib.mkOption {
    type = lib.types.attrs;
    description = "user information for git";
    default = {
      name = "DataHearth";
      email = "dev@antoine-langlois.net";
    };
  };
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
in
{
  options.home_modules.git = {
    inherit
      enable
      signingKey
      user
      extraConfig
      extraAliases
      ;
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      aliases = {
        co = "checkout";
        p = "push";
        c = "commit";
        s = "status";
        pu = "pull";
        logs = "log --graph --oneline";
        update-remote = "remote update origin --prune";
        tags = "git tag --list";
      }
      // cfg.extraAliases;
      difftastic.enable = true;
      lfs.enable = true;
      signing = lib.mkIf (cfg.signingKey != null) {
        signByDefault = true;
        key = cfg.signingKey;
      };
      userName = cfg.user.name;
      userEmail = cfg.user.email;
      extraConfig = {
        init.defaultBranch = "main";
      }
      // cfg.extraConfig;
    };
  };
}
