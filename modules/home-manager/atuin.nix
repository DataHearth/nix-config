{
  lib,
  config,
  ...
}:
let
  cfg = config.home_modules.atuin;
in
{
  options.home_modules.atuin = {
    enable = lib.mkEnableOption "atuin shell history";
  };

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        dialect = "uk";
        update_check = false;
        sync.records = true;
      };
    };
  };
}
