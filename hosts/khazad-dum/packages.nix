{ pkgs, ... }:
let
  customPackages = import ../../packages { inherit pkgs; };
in
{
  environment.systemPackages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland

    customPackages.f5vpn
    customPackages.f5epi

    clamav
    doggo
    sbctl
    procs
    duf
  ];

  systemd.tmpfiles.packages = [
    customPackages.f5vpn
    customPackages.f5epi
  ];

  # svpn needs setuid root to create tun devices
  security.wrappers.svpn = {
    source = "${customPackages.f5vpn}/opt/f5/vpn/svpn";
    owner = "root";
    group = "root";
    setuid = true;
  };

}
