{
  lib,
  config,
  ...
}:
let
  cfg = config.home_modules.walker;
in
{
  options.home_modules.walker = {
    enable = lib.mkEnableOption "walker application launcher";
  };

  config = lib.mkIf cfg.enable {
    services.walker = {
      enable = true;
      systemd.enable = true;
    };
  };
}
