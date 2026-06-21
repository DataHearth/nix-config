{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.home_modules.okular;
in
{
  options.home_modules.okular = {
    enable = lib.mkEnableOption "okular";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.kdePackages.okular;
      defaultText = lib.literalExpression "pkgs.kdePackages.okular";
      description = "The Okular package to use.";
    };

    defaultPdfViewer = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Register Okular as the default handler for application/pdf.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.mimeApps = lib.mkIf cfg.defaultPdfViewer {
      enable = true;
      defaultApplications."application/pdf" = "org.kde.okular.desktop";
    };
  };
}
