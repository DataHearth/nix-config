{ ... }:
{
  imports = [
    ./modules.nix
    ./packages.nix
    ./services.nix
    ./ui.nix
  ] ++ (import ../../../modules/home-manager);
  home = {
    username = "datahearth";
    homeDirectory = "/home/datahearth";
    stateVersion = "24.11";
  };

  xdg.enable = true;
}
