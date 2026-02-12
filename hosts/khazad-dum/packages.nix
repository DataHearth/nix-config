{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
  ];
}
