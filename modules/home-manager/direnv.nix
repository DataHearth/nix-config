{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.direnv;
in
{
  options.home_modules.direnv = {
    enable = lib.mkEnableOption "direnv with nix-direnv integration";
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      mise.enable = true;

      # nix-direnv's _nix_refresh_gcroots touches $layout_dir/flake-profile-*
      # to keep `nh clean` off the devShell, but that glob also hits the
      # direnv-watched flake-profile-*.rc. Every load then invalidates every
      # other shell in the directory, which reloads, touches, and invalidates
      # back — endless reloads reprinting the devshell menu on ordinary
      # commands. Only the gcroots are symlinks; the .rc is a regular file.
      # Drop this once nix-direnv stops globbing the .rc.
      stdlib = ''
        _nix_refresh_gcroots() {
          local layout_dir
          layout_dir=$(direnv_layout_dir)
          ${pkgs.findutils}/bin/find "$layout_dir" -maxdepth 2 -type l \
            -exec ${pkgs.coreutils}/bin/touch -h {} + 2>/dev/null
        }
      '';
    };
  };
}
