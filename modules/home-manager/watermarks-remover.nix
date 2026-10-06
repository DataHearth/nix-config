{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.watermarks-remover;

  version = "0.7.0";
  src = pkgs.fetchFromGitHub {
    owner = "guillaumemeyer";
    repo = "watermarks-remover";
    rev = "v${version}";
    hash = "sha256-day6c49O/TxV4AK9GLn5hEO3+8p01IK10EEHKDbeLFo=";
  };
in
{
  options.home_modules.watermarks-remover = {
    enable = lib.mkEnableOption "the watermarks-remover HTTP service backing the remove-ai-marks Claude Code skill";
  };

  # No rewrite backend is configured, so /clean rejects text files with a 400;
  # images, PDFs and office documents still clean. Text stays with the plugin's
  # PostToolUse hook, which needs no service.
  # The Claude Code plugin updates from its marketplace while this is pinned:
  # bump `version` and `hash` when the plugin moves.
  config = lib.mkIf cfg.enable {
    systemd.user.services.watermarks-remover = {
      Unit.Description = "watermarks-remover HTTP service";

      Service = {
        # The default strategy file is the relative path config/clean_strategy.json.
        WorkingDirectory = "${src}";
        ExecStart = "${lib.getExe pkgs.python3} ${src}/service/scripts/server.py";
        Environment = [
          "PATH=${
            lib.makeBinPath [
              pkgs.exiftool
              pkgs.qpdf
              pkgs.c2patool
              pkgs.ghostscript
            ]
          }"
          "WATERMARKS_SERVER_VERSION=${version}"
        ];
        Restart = "on-failure";
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
