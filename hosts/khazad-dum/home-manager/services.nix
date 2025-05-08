{ pkgs, ... }:
{
  services = {
    ssh-agent.enable = true;

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
