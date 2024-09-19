{ config, lib, ... }:
let
  cfg = config.hm.ssh;

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
  options.hm.ssh = {
    inherit enable addKeysToAgent;
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      addKeysToAgent = cfg.addKeysToAgent;
    };
  };
}
