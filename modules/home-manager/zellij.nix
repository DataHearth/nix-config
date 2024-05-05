{ lib, config, ... }:
with lib;
let
  cfg = config.hm.zellij;

  enable = mkEnableOption "zellij";
  copy_command = mkOption {
    type = types.str;
    description = "Command to execute when copying text";
    example = "wl-copy";
  };
in {
  options.hm.zellij = { inherit enable copy_command; };

  config = mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        theme = "catppuccin-macchiato";
        copy_command = cfg.copy_command;
      };
    };
  };
}
