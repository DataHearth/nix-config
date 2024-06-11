{ ... }: {
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Paris";
  console.keyMap = "fr";
  virtualisation.docker.enable = true;
  xdg.portal.enable = true;
}
