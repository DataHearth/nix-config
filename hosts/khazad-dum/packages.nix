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

  # Fix F5 VPN connectivity issues when GlobalProtect is active:
  # 1. Configure per-link DNS in resolved so F5 internal names resolve
  #    while public DNS keeps working (bypasses svpn's resolv.conf overwriting).
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="tun0", TAG+="systemd", ENV{SYSTEMD_WANTS}="f5vpn-fix.service"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="tailscale0", TAG+="systemd", ENV{SYSTEMD_WANTS}="tailscale-dns.service"
  '';

  # systemd.services.gp-dns-setup = {
  #   description = "Configure resolved DNS for GlobalProtect (tun0)";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
  #     ExecStart = pkgs.writeShellScript "gp-dns-setup" ''
  #       ${pkgs.systemd}/bin/resolvectl dns tun0 10.30.18.15 10.30.2.19
  #       ${pkgs.systemd}/bin/resolvectl domain tun0 "~."
  #     '';
  #   };
  # };

  systemd.services.tailscale-dns = {
    description = "Configure resolved DNS for Tailscale";
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = 300;
      ExecStart = pkgs.writeShellScript "tailscale-dns" ''
        # Wait for Tailscale to be connected before claiming DNS
        until ${pkgs.tailscale}/bin/tailscale status --peers=false >/dev/null 2>&1; do
          sleep 2
        done
        ${pkgs.systemd}/bin/resolvectl dns tailscale0 100.100.100.100
        ${pkgs.systemd}/bin/resolvectl domain tailscale0 "~."
      '';
    };
  };

  systemd.services.f5vpn-fix = {
    description = "Fix routing and DNS for F5 VPN (tun1)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "f5vpn-fix" ''
        # Remove GP's conflicting policy routing rule
        ${pkgs.iproute2}/bin/ip rule del to 1.1.1.1 lookup 200 2>/dev/null || true

        # Wait for interface to be registered with resolved
        sleep 2
        ${pkgs.systemd}/bin/resolvectl dns tun0 100.105.5.112 100.105.6.192
        ${pkgs.systemd}/bin/resolvectl domain tun0 "~airbus.corp" "~intra.corp"
      '';
    };
  };
}
