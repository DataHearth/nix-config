{ config, ... }:
{
  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = "/run/secrets/tailscale_keys/valinor";
      useRoutingFeatures = "server";
      extraUpFlags = [
        "--accept-dns=false"
        "--advertise-tags=\"tag:actinium\""
        "--advertise-routes=\"192.168.1.0/24\""
      ];
    };

    openssh = {
      enable = true;
      settings.PrintMotd = true;
      extraConfig = ''
        Match User ${config.users.users.actinium.name}
          AuthenticationMethods publickey
          PasswordAuthentication no
      '';
    };

    logrotate = {
      enable = true;
      settings =
        let
          war_goats_logs = "/mnt/Erebor/War-goats/logs";
        in
        {
          header = {
            dateext = true;
          };

          "${war_goats_logs}/traefik/access.log" = {
            size = "50M";
            rotate = 30;
            notifempty = true;
            postrotate = ''
              docker kill --signal 'USR1' reverse-proxy-traefik-1
            '';
          };
        };
    };

    kubo = {
      enable = true;
      autoMount = true;
      enableGC = true;

      settings = {
        Addresses = {
          API = "/ip4/192.168.1.2/tcp/5001";
        };
        API.HTTPHeaders = {
          Access-Control-Allow-Origin = [
            "http://192.168.1.2:5001"
            "http://localhost:3000"
            "http://127.0.0.1:5001"
            "https://webui.ipfs.io"
          ];
          Access-Control-Allow-Methods = [
            "PUT"
            "POST"
          ];
        };
      };
    };
  };
}
