{ ... }:
{
  services = {
    gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      pinentryFlavor = "qt";
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    };
    
    ssh-agent.enable = true;
  };
}
