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
    sessionPath = [
      "$(go env GOBIN)"
      "$HOME/.cargo/bin"
    ];
  };

  xdg.enable = true;
}
