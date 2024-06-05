{ lib, config, ... }:
let
  cfg = config.hm.zellij;

  enable = lib.mkEnableOption "zellij";
  copy_command = lib.mkOption {
    type = lib.types.str;
    description = "Command to execute when copying text";
    example = "wl-copy";
  };
in {
  options.hm.zellij = { inherit enable copy_command; };

  config = lib.mkIf cfg.enable {
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
