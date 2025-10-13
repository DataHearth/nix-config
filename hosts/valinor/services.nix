{
  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = "/run/secrets/tailscale_keys/valinor";
      useRoutingFeatures = "server";
      extraUpFlags = [
        "--accept-dns=false"
        "--advertise-routes='192.168.1.0/24'"
      ];
    };

    openssh = {
      enable = true;
      settings.PrintMotd = true;
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
  };
}
