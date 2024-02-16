{ ... }:
{
  services = {
    gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      pinentryFlavor = "qt";
    };
    
    ssh-agent.enable = true;
  };
}