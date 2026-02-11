{
  lib,
  config,
  ...
}:
let
  cfg = config.home_modules.vscode;
in
{
  options.home_modules.vscode = {
    enable = lib.mkEnableOption "Visual Studio Code";
  };

  config = lib.mkIf cfg.enable {
    programs.vscode.enable = true;
  };
}
