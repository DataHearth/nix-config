{
  config,
  lib,
  pkgs,
  ...
}:
let
  # iwd 3.12 leaves wlan0 in RFC2863 linkmode=dormant after every connect:
  # its IF_OPER_UP netlink call races the driver's carrier-down window, the
  # kernel silently drops it (set_operstate only accepts UP from
  # DORMANT/TESTING/UNKNOWN), and iwd's retry never lands. A dormant link
  # has no carrier as far as systemd-resolved is concerned, so wlan0's DNS
  # scope deactivates and split-horizon names silently resolve via public
  # fallback servers. iproute2 cannot set operstate, hence this helper.
  # Drop it once iwd promotes operstate reliably.
  operstateUpSrc = pkgs.writeText "operstate-up.c" ''
    #include <linux/netlink.h>
    #include <linux/rtnetlink.h>
    #include <net/if.h>
    #include <stdio.h>
    #include <string.h>
    #include <sys/socket.h>
    #include <unistd.h>

    /* from <linux/if.h>, which conflicts with <net/if.h> */
    #define IF_OPER_UP 6
    #define IF_LINK_MODE_DEFAULT 0

    int main(int argc, char **argv)
    {
        if (argc != 2) {
            fprintf(stderr, "usage: %s <interface>\n", argv[0]);
            return 2;
        }

        unsigned int ifindex = if_nametoindex(argv[1]);
        if (ifindex == 0) {
            perror(argv[1]);
            return 1;
        }

        char buf[NLMSG_SPACE(sizeof(struct ifinfomsg)) + 2 * RTA_SPACE(1)];
        memset(buf, 0, sizeof(buf));

        struct nlmsghdr *nh = (struct nlmsghdr *)buf;
        nh->nlmsg_type = RTM_SETLINK;
        nh->nlmsg_flags = NLM_F_REQUEST | NLM_F_ACK;
        nh->nlmsg_seq = 1;
        nh->nlmsg_len = NLMSG_LENGTH(sizeof(struct ifinfomsg));

        struct ifinfomsg *ifi = NLMSG_DATA(nh);
        ifi->ifi_family = AF_UNSPEC;
        ifi->ifi_index = (int)ifindex;

        /* linkmode back to default so the kernel recomputes operstate=UP
         * from carrier on its own after later flaps (self-healing until
         * iwd's next connect re-imposes dormant) */
        struct rtattr *rta = (struct rtattr *)(buf + NLMSG_ALIGN(nh->nlmsg_len));
        rta->rta_type = IFLA_LINKMODE;
        rta->rta_len = RTA_LENGTH(1);
        *(unsigned char *)RTA_DATA(rta) = IF_LINK_MODE_DEFAULT;
        nh->nlmsg_len = NLMSG_ALIGN(nh->nlmsg_len) + RTA_ALIGN(rta->rta_len);

        rta = (struct rtattr *)(buf + NLMSG_ALIGN(nh->nlmsg_len));
        rta->rta_type = IFLA_OPERSTATE;
        rta->rta_len = RTA_LENGTH(1);
        *(unsigned char *)RTA_DATA(rta) = IF_OPER_UP;
        nh->nlmsg_len = NLMSG_ALIGN(nh->nlmsg_len) + RTA_ALIGN(rta->rta_len);

        int fd = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
        if (fd < 0) {
            perror("socket");
            return 1;
        }

        struct sockaddr_nl kernel = { .nl_family = AF_NETLINK };
        if (sendto(fd, buf, nh->nlmsg_len, 0, (struct sockaddr *)&kernel,
                   sizeof(kernel)) < 0) {
            perror("sendto");
            return 1;
        }

        char resp[4096];
        ssize_t n = recv(fd, resp, sizeof(resp), 0);
        close(fd);
        if (n < (ssize_t)NLMSG_LENGTH(sizeof(struct nlmsgerr))) {
            fprintf(stderr, "netlink: short or missing ack\n");
            return 1;
        }

        struct nlmsghdr *rnh = (struct nlmsghdr *)resp;
        if (rnh->nlmsg_type == NLMSG_ERROR) {
            struct nlmsgerr *err = NLMSG_DATA(rnh);
            if (err->error != 0) {
                fprintf(stderr, "netlink: %s\n", strerror(-err->error));
                return 1;
            }
        }
        return 0;
    }
  '';
  operstateUp = pkgs.runCommandCC "operstate-up" { } ''
    mkdir -p $out/bin
    cc -O2 -o $out/bin/operstate-up ${operstateUpSrc}
  '';
in
{
  # systemd-resolved provides split-DNS: it routes queries to the right
  # DNS server based on the interface/domain (e.g. corporate domains go
  # through VPN DNS, everything else through the default interface).
  # (F5-specific resolv.conf/DNS handling lives in modules/nixos/f5.nix.)
  services.resolved = {
    enable = true;
    # No fallback servers: if a link's DNS scope dies (e.g. the iwd
    # dormant-operstate bug above), resolution must fail loudly instead of
    # silently serving public answers for split-horizon names via 1.1.1.1.
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
      # Re-assert operstate after every Wi-Fi activation; see operstateUp.
      dispatcherScripts = [
        {
          type = "basic";
          source = pkgs.writeShellScript "wlan0-operstate-up" ''
            if [ "$1" = "wlan0" ] && [ "$2" = "up" ]; then
              ${operstateUp}/bin/operstate-up wlan0
            fi
          '';
        }
      ];
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
