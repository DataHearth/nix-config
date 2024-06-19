{ ... }: {
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Paris";
  console.keyMap = "fr";
  virtualisation.docker.enable = true;
  xdg.portal.enable = true;
  environment.pathsToLink = [ "/share/zsh" ]; # add system CLI completion
}
