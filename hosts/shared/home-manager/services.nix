{ pkgs, lib, ... }: {
  services = {
    playerctld.enable = true;
    ssh-agent.enable = true;
    blueman-applet.enable = lib.mkDefault true;
    network-manager-applet.enable = true;

    nextcloud-client = {
      enable = true;
      startInBackground = true;
    };

    gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      pinentryPackage = pkgs.pinentry-gnome3;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    };
  };
}
