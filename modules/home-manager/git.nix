{ config, lib, options, ... }:
with lib;
let
  cfg = config.hm.git;

  enable = mkEnableOption "git";
  signingKey = mkOption {
    type = types.nonEmptyStr;
    description = "The GPG key to use for signing commits";
    example = "A12925470298BFEE7EE092B3946E2D0C410C7B3D";
  };
  user = mkOption {
    type = types.attrs;
    description = "user information for git";
    default = {
      name = "DataHearth";
      email = "dev@antoine-langlois.net";
    };
  };
  extraConfig = mkOption {
    type = types.attrs;
    description = "Extra git configuration";
    default = {};
  };
  extraAliases = mkOption {
    type = types.attrs;
    description = "Extra git aliases";
    default = {};
  };
in
{
  options.hm.git = {
    inherit enable signingKey user extraConfig extraAliases;
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      aliases = {
        co = "checkout";
        p = "push";
        c = "commit";
        s = "status";
        pu = "pull";
        logs = "log --graph --oneline";
        remote-update = "remote update origin --prune";
      } // cfg.extraAliases;
      difftastic.enable = true;
      lfs.enable = true;
      signing = mkIf (builtins.hasAttr "signingKey" cfg) {
        signByDefault = true;
        key = cfg.signingKey;
      };
      userName = cfg.user.name;
      userEmail = cfg.user.email;
      extraConfig = {
        init.defaultBranch = "main";
      } // cfg.extraConfig;
    };
  };
}
