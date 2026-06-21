{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos_modules.f5;
  customPackages = import ../../packages { inherit pkgs; };
in
{
  options.nixos_modules.f5 = {
    enable = lib.mkEnableOption "F5 VPN (Airbus) client with split-tunnel routing/DNS fixes and supporting kernel/firewall settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      customPackages.f5vpn
      customPackages.f5epi
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

    # Without this the firewall silently drops the VPN's inbound return traffic
    # on tun0: replies are visible in tcpdump but never delivered to the socket
    # (ICMP InMsgs +0, conntrack invalid +0 — a plain nftables input drop, and
    # ping only succeeds with the ruleset flushed). Trusting tun0 admits it.
    networking.firewall.trustedInterfaces = [ "tun0" ];

    # The F5 client overwrites /etc/resolv.conf with corporate-only nameservers
    # that NXDOMAIN public domains. Tools using glibc/NSS (curl, xh) go through
    # the systemd-resolved stub, but Nix reads /etc/resolv.conf directly and
    # fails. Pin it immutable so the VPN can't overwrite it, forcing all DNS
    # through the resolved stub (which does split-DNS per the f5-fix service).
    system.activationScripts.immutable-resolv-conf = lib.stringAfter [ "etc" ] ''
      ${pkgs.e2fsprogs}/bin/chattr -i /etc/resolv.conf 2>/dev/null || true
      cat > /etc/resolv.conf <<EOF
      nameserver 127.0.0.53
      search airbus.corp lan
      EOF
      ${pkgs.e2fsprogs}/bin/chattr +i /etc/resolv.conf
    '';

    # Run the routing/DNS fix when svpn brings tun0 up. Configures per-link DNS
    # in resolved so F5 internal names resolve while public DNS keeps working.
    # Also re-pin tailnet routes (the f5-fix /12 overlaps the tailnet, so the
    # /32s must be (re)asserted whenever tun0 appears).
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="tun0", TAG+="systemd", ENV{SYSTEMD_WANTS}="f5-fix.service f5-tailscale-routes.service"
    '';

    systemd.services.f5-fix = {
      description = "Fix routing and DNS for F5 VPN";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "f5-fix" ''
          # Remove the conflicting policy routing rule svpn installs
          ${pkgs.iproute2}/bin/ip rule del to 1.1.1.1 lookup 200 2>/dev/null || true

          # The VPN only pushes routes for 14.0.0.0/8 and 100.96.0.0/12
          # (see DNS_SPLIT/LAN0 in ~/.F5Networks/vpn.log). Private corporate
          # instances live in 10.0.0.0/8 (e.g. the 10.84.x Jenkins boxes) and
          # are NOT tunneled by policy, so add the route ourselves. Safe here:
          # the local LAN is 192.168.1.0/24 and Docker is 172.x, no 10.x overlap.
          ${pkgs.iproute2}/bin/ip route replace 10.0.0.0/8 dev tun0

          # Wait for interface to be registered with resolved
          sleep 2
          ${pkgs.systemd}/bin/resolvectl dns tun0 100.105.5.112 100.105.6.192
          ${pkgs.systemd}/bin/resolvectl domain tun0 "~airbus.corp" "~intra.corp"
        '';
      };
    };

    # F5's pushed 100.96.0.0/12 (added by f5-fix) is a subset of Tailscale's
    # 100.64.0.0/10 CGNAT range, so any tailnet peer in 100.96-100.111 gets
    # hijacked onto tun0 (incl. the PiHole resolver, which breaks tailnet DNS).
    # Pin every such peer to tailscale0 with a /32 — longest prefix beats the
    # /12. Runs on tailscale startup and whenever tun0 appears (udev rule above).
    systemd.services.f5-tailscale-routes = {
      description = "Pin tailnet routes overlapping the F5 100.96.0.0/12 to tailscale0";
      wantedBy = [ "tailscaled.service" ];
      after = [ "tailscaled.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "f5-tailscale-routes" ''
          # Self + every peer IP, kept to IPv4 tailnet addresses whose second
          # octet is 96-111 (i.e. inside F5's 100.96.0.0/12); leave the rest.
          ${pkgs.tailscale}/bin/tailscale status --json \
            | ${pkgs.jq}/bin/jq -r '
                [.Self, (.Peer[]?)]
                | .[].TailscaleIPs[]?
                | select(startswith("100."))
                | select((split(".")[1] | tonumber) >= 96 and (split(".")[1] | tonumber) <= 111)
              ' \
            | while read -r ip; do
                ${pkgs.iproute2}/bin/ip route replace "$ip/32" dev tailscale0
              done
        '';
      };
    };
  };
}
