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

    matchBlocks = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "SSH match blocks for host-specific configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          addKeysToAgent = cfg.addKeysToAgent;
        };
      } // cfg.matchBlocks;
    };
  };
}
