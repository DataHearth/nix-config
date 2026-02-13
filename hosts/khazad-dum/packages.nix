{ pkgs, ... }:
let
  customPackages = import ../../packages { inherit pkgs; };
in
{
  environment.systemPackages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    clamav
    customPackages.f5vpn
    customPackages.f5epi
    doggo
  ];

  systemd.tmpfiles.packages = [
    customPackages.f5vpn
    customPackages.f5epi
  ];
  systemd.packages = [ customPackages.f5vpn ];
  services.udev.packages = [ customPackages.f5vpn ];

  # svpn needs setuid root to create tun devices
  security.wrappers.svpn = {
    source = "${customPackages.f5vpn}/opt/f5/vpn/svpn";
    owner = "root";
    group = "root";
    setuid = true;
  };
}
