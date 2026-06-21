{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland

    clamav
    doggo
    sbctl
    procs
    duf
  ];

  programs = {
    steam.enable = true;
  };
}
