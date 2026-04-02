{
  config,
  lib,
  pkgs,
  ...
}:
{
  # systemd-resolved provides split-DNS: it routes queries to the right
  # DNS server based on the interface/domain (e.g. corporate domains go
  # through VPN DNS, everything else through the default interface).
  # The F5 VPN client overwrites /etc/resolv.conf with corporate-only
  # nameservers that return NXDOMAIN for public domains (like github.com).
  # Tools using glibc/NSS (curl, xh) bypass this via systemd-resolved's
  # stub listener, but Nix reads /etc/resolv.conf directly and fails.
  # The activation script below makes /etc/resolv.conf immutable so the
  # VPN can't overwrite it, forcing all DNS through the resolved stub.
  services.resolved.enable = true;

  networking = {
    hostName = "khazad-dum";
    wireless.iwd.enable = true;
    nftables.enable = true;
    firewall.enable = true;
    extraHosts = ''
      127.0.0.1 etlm.cluster.local
      192.168.1.254 mabbox.bytel.fr
    '';

    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi.backend = "iwd";
      unmanaged = [ "interface-name:tun*" ];
      ensureProfiles = {
        environmentFiles = [ config.sops.templates."wifi-cirdan-env".path ];
        profiles = {
          cirdan = {
            connection = {
              id = "Cirdan";
              type = "wifi";
            };
            wifi = {
              ssid = "Cirdan";
              mode = "infrastructure";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$WIFI_CIRDAN_PSK";
            };
            ipv4 = {
              method = "auto";
              dns = "192.168.1.102;1.1.1.1;1.0.0.1;";
              ignore-auto-dns = "true";
            };
            ipv6 = {
              method = "auto";
              ignore-auto-dns = "true";
            };
          };
          cirdan-plus = {
            connection = {
              id = "Cirdan-Plus";
              type = "wifi";
              autoconnect = "true";
            };
            wifi = {
              ssid = "Cirdan-Plus";
              mode = "infrastructure";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$WIFI_CIRDAN_PSK";
            };
            ipv4 = {
              method = "auto";
              dns = "192.168.1.102;1.1.1.1;1.0.0.1;";
              ignore-auto-dns = "true";
            };
            ipv6 = {
              method = "auto";
              ignore-auto-dns = "true";
            };
          };
        };
      };
    };
  };

  system.activationScripts.immutable-resolv-conf = lib.stringAfter [ "etc" ] ''
    ${pkgs.e2fsprogs}/bin/chattr -i /etc/resolv.conf 2>/dev/null || true
    cat > /etc/resolv.conf <<EOF
    nameserver 127.0.0.53
    search airbus.corp lan
    EOF
    ${pkgs.e2fsprogs}/bin/chattr +i /etc/resolv.conf
  '';

  # Fix F5 VPN connectivity issues when GlobalProtect is active:
  # Configure per-link DNS in resolved so F5 internal names resolve
  # while public DNS keeps working (bypasses svpn's resolv.conf overwriting).
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="tun0", TAG+="systemd", ENV{SYSTEMD_WANTS}="f5vpn-fix.service"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="tailscale0", TAG+="systemd", ENV{SYSTEMD_WANTS}="tailscale-dns.service"
  '';

  # Route all DNS through the tailnet PiHole (100.109.226.49).
  # MagicDNS is disabled; PiHole resolves both tailnet and public names.
  systemd.services.tailscale-dns = {
    description = "Configure resolved DNS for Tailscale";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = pkgs.writeShellScript "tailscale-dns" ''
        ${pkgs.systemd}/bin/resolvectl dns tailscale0 100.109.226.49
        ${pkgs.systemd}/bin/resolvectl domain tailscale0 "~."
      '';
    };
  };

  systemd.services.f5vpn-fix = {
    description = "Fix routing and DNS for F5 VPN";
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
