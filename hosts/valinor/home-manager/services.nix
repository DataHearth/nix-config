{
  services = {
    ssh-agent.enable = true;

    gpg-agent = {
      enable = true;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    };
  };
}
