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
    # The pin must be lifted *before* setup-etc.pl runs, not after: resolved
    # declares /etc/resolv.conf as a symlink to its stub, and an immutable file
    # sitting there makes the `etc` step fail, aborting the whole activation
    # before any later script could unlock it.
    system.activationScripts.unlock-resolv-conf.text = ''
      if [ -f /etc/resolv.conf ] && [ ! -L /etc/resolv.conf ]; then
        ${pkgs.e2fsprogs}/bin/chattr -i /etc/resolv.conf
      fi
    '';
    system.activationScripts.etc.deps = [ "unlock-resolv-conf" ];

    system.activationScripts.immutable-resolv-conf = lib.stringAfter [ "etc" ] ''
      # setup-etc.pl has just put resolved's stub symlink back. Writing through
      # it would truncate the stub and pin resolved's own file immutable, so
      # replace the symlink with a regular file instead.
      rm -f /etc/resolv.conf
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

          # LAN0 only tunnels 14.0.0.0/8 and 100.96.0.0/12 (see szParams in
          # ~/.F5Networks/vpn.log), but plenty of corporate services resolve
          # into 10.0.0.0/8 and are NOT tunneled by policy — e.g. the modelops
          # platform behind *.airbus-v.corp lands on 10.102.191.x. Route it
          # ourselves. Safe: local LAN is 192.168.1.0/24, Docker is 172.x and
          # the tailnet is 100.64.0.0/10 — nothing overlaps 10/8.
          ${pkgs.iproute2}/bin/ip route replace 10.0.0.0/8 dev tun0

          # Wait for interface to be registered with resolved
          sleep 2
          ${pkgs.systemd}/bin/resolvectl dns tun0 100.105.5.112 100.105.6.192
          # Mirrors DNS_SPLIT0 from the VPN's negotiated policy (see szParams in
          # ~/.F5Networks/vpn.log). resolved matches routing domains on label
          # boundaries, so "~airbus.corp" does NOT cover airbus-v.corp — every
          # split domain has to be listed explicitly or it resolves via public
          # DNS and NXDOMAINs. Re-check this list if Airbus changes DNS_SPLIT0.
          ${pkgs.systemd}/bin/resolvectl domain tun0 \
            "~airbus.corp" "~airbus-v.corp" "~intra.corp" "~aero.bombardier.net"
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
