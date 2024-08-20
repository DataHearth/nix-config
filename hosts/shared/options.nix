{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Paris";
  console.keyMap = "fr";
  virtualisation.docker.enable = true;
  xdg.portal.enable = true;
  custom.neovim.enable = true;

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  networking = {
    networkmanager = {
      enable = true;
      dns = "none";
    };
    nameservers = [
      "100.65.209.18"
      "fd7a:115c:a1e0::4641:d112"
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };

  programs = {
    hyprland = { enable = true; };
    zsh.enable = true;
    wireshark.enable = true;
  };

  environment = {
    shells = with pkgs; [ zsh bash ];
    systemPackages = with pkgs; [
      pinentry
      home-manager
      docker
      looking-glass-client
      ntfs3g
      libheif
      libheif.out
    ];
    pathsToLink = [ "share/thumbnailers" "/share/zsh" ];
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "Mononoki" ]; })
    corefonts
  ];
}
