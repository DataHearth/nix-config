{
  config,
  pkgs,
  ...
}:
{
  # systemd-resolved provides split-DNS: it routes queries to the right
  # DNS server based on the interface/domain (e.g. corporate domains go
  # through VPN DNS, everything else through the default interface).
  # (F5-specific resolv.conf/DNS handling lives in modules/nixos/f5.nix.)
  services.resolved = {
    enable = true;
    # No fallback servers: if a link's DNS scope dies, resolution must fail
    # loudly instead of silently serving public answers for split-horizon
    # names via 1.1.1.1.
    # Must be an explicit empty assignment — an empty list would omit the
    # line and keep systemd's compiled-in fallback list.
    settings.Resolve.FallbackDNS = "";
  };

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
          la-maison-du-bonheur = {
            connection = {
              id = "LaMaisonDuBonheur";
              type = "wifi";
              autoconnect = "true";
            };
            wifi = {
              ssid = "LaMaisonDuBonheur";
              mode = "infrastructure";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$WIFI_LA_MAISON_DU_BONHEUR_PSK";
            };
          };
        };
      };
    };
  };

  # Route all DNS through the tailnet PiHole (100.109.226.49) while the
  # Tailscale backend is Running. MagicDNS is disabled; PiHole resolves both
  # tailnet and public names.
  # Track the backend state, not tailscaled.service's lifetime: `tailscale
  # down` stops the backend but leaves the daemon (and anything bound to it)
  # running, which used to strand a stale `~.` catch-all pointing at an
  # unreachable resolver. Re-asserting while Running also survives resolved
  # restarts, which drop per-link config.
  systemd.services.tailscale-dns = {
    description = "Sync resolved DNS routing with Tailscale backend state";
    wantedBy = [ "tailscaled.service" ];
    bindsTo = [ "tailscaled.service" ];
    after = [ "tailscaled.service" ];
    path = [
      pkgs.tailscale
      pkgs.jq
      pkgs.systemd
    ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 5;
      # Runs on any stop, including crashes and the bindsTo teardown.
      ExecStopPost = "${pkgs.systemd}/bin/resolvectl revert tailscale0";
    };
    script = ''
      last=""
      while :; do
        state="$(tailscale status --json | jq -r .BackendState)"
        if [ "$state" = "Running" ]; then
          resolvectl dns tailscale0 100.109.226.49
          resolvectl domain tailscale0 "~."
        elif [ "$last" = "Running" ] || [ -z "$last" ]; then
          resolvectl revert tailscale0
        fi
        last="$state"
        sleep 10
      done
    '';
  };
}
