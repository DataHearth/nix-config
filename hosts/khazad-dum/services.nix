{ pkgs, ... }:
{
  services = {
    fprintd.enable = true;
    power-profiles-daemon.enable = true;
    deluge.enable = true;
    gnome.gnome-keyring.enable = true;
    blueman.enable = true;

    tailscale = {
      enable = true;
      extraUpFlags = [
        "--accept-dns=false"
        "--accept-routes"
      ];
    };

    xserver = {
      enable = true;
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
      enable = true;
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
      settings.Addresses.API = "/ip4/127.0.0.1/tcp/5001";
    };
  };
}
