{
  lib,
  config,
  ...
}:
let
  cfg = config.home_modules.yazi;

  enable = lib.mkEnableOption "yazi";
in
{
  options.home_modules.yazi = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      settings = {
        mgr = {
          show_hidden = true;
          show_symlink = true;
        };
      };
    };
  };
}
