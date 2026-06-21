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
  # (F5-specific resolv.conf/DNS handling lives in modules/nixos/f5.nix.)
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
              autoconnect = "false";
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
              dns = "192.168.1.102";
              ignore-auto-dns = "true";
            };
            ipv6 = {
              method = "auto";
              ignore-auto-dns = "true";
              # Bbox advertises a 1500 link MTU via RA, but Bouygues' native
              # IPv6 path only carries 1420 bytes and ICMPv6 "Packet Too Big"
              # is filtered upstream, so PMTUD blackholes: anything >1420
              # silently dies and dual-stack sites time out. Clamp to the
              # measured path MTU so the kernel never sends oversized packets.
              mtu = "1420";
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
              dns = "192.168.1.102";
              ignore-auto-dns = "true";
            };
            ipv6 = {
              method = "auto";
              ignore-auto-dns = "true";
              # See Cirdan above: clamp IPv6 MTU to the Bbox path MTU (1420)
              # to work around the upstream PMTUD blackhole.
              mtu = "1420";
            };
          };
        };
      };
    };
  };

  # Route all DNS through the tailnet PiHole (100.109.226.49).
  # MagicDNS is disabled; PiHole resolves both tailnet and public names.
  # bindsTo tailscaled ensures ExecStop (resolvectl revert) runs when
  # Tailscale stops, so queries fall back to wlan0's local DNS.
  systemd.services.tailscale-dns = {
    description = "Configure resolved DNS for Tailscale";
    wantedBy = [ "tailscaled.service" ];
    bindsTo = [ "tailscaled.service" ];
    after = [ "tailscaled.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "tailscale-dns" ''
        ${pkgs.systemd}/bin/resolvectl dns tailscale0 100.109.226.49
        ${pkgs.systemd}/bin/resolvectl domain tailscale0 "~."
      '';
      ExecStop = pkgs.writeShellScript "tailscale-dns-stop" ''
        ${pkgs.systemd}/bin/resolvectl revert tailscale0
      '';
    };
  };
}
