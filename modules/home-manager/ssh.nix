{ config, lib, ... }:
let
  cfg = config.home_modules.ssh;

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
in
{
  options.home_modules.ssh = {
    inherit enable addKeysToAgent;
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        addKeysToAgent = cfg.addKeysToAgent;
      };
    };
  };
}
