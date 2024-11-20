{ ... }:
{
  imports = [
    ./modules.nix
    ./packages.nix
    ./services.nix
  ] ++ (import ../../../modules/home-manager);
  home = {
    username = "datahearth";
    homeDirectory = "/home/datahearth";
    stateVersion = "24.05";
    sessionPath = [
      "$(go env GOBIN)"
      "$HOME/.cargo/bin"
    ];
  };

  xdg.enable = true;
}
