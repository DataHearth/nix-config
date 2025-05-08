{ pkgs, lib, ... }:
{
  services = {
    fprintd.enable = true;
    power-profiles-daemon.enable = true;
    deluge.enable = true;
    gnome.gnome-keyring.enable = lib.mkDefault true;
    blueman.enable = lib.mkDefault true;

    tailscale = {
      enable = true;
      extraUpFlags = [
        "--accept-dns=false"
        "--accept-routes"
      ];
    };

    xserver = {
      enable = lib.mkDefault true;
      xkb.layout = "fr";
    };

    pipewire = {
      enable = true;
      pulse.enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };
    };

    greetd = {
      enable = lib.mkDefault true;
      vt = 9; # Fix lines on screen

      settings.default_session = {
        command = ''${pkgs.greetd.tuigreet}/bin/tuigreet --user-menu --time --greeting "Speak Friend and Enter" --remember --remember-user-session --asterisks --cmd Hyprland'';
        user = "datahearth";
      };
    };

    kubo = {
      enable = true;
      autoMount = true;
      enableGC = true;

      settings = {
        Addresses.API = "/ip4/127.0.0.1/tcp/5001";
        API.HTTPHeaders = {
          Access-Control-Allow-Origin = [
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
