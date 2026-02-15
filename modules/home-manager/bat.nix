{
  lib,
  config,
  ...
}:
let
  cfg = config.home_modules.bat;
in
{
  options.home_modules.bat = {
    enable = lib.mkEnableOption "bat";
  };

  config = lib.mkIf cfg.enable {
    programs.bat.enable = true;
  };
}
