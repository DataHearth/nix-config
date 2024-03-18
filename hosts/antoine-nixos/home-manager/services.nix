{ pkgs, ... }:
{
  services = {
    playerctld.enable = true;
    ssh-agent.enable = true;

    nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
    gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      pinentryPackage = pkgs.pinentry-qt;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    }; 
  };
}
