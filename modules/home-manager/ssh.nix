{
  config,
  lib,
  ...
}:
let
  cfg = config.home_modules.ssh;
in
{
  options.home_modules.ssh = {
    enable = lib.mkEnableOption "ssh";

    addKeysToAgent = lib.mkOption {
      type = lib.types.enum [
        "yes"
        "no"
        "confirm"
        "ask"
      ];
      default = "yes";
      description = "Add automatically private SSH keys to ssh-agent";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "SSH host configuration blocks (see programs.ssh.settings)";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          AddKeysToAgent = cfg.addKeysToAgent;
        };
      }
      // cfg.settings;
    };
  };
}
