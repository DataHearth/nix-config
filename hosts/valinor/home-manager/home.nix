{ ... }:
{
  imports = [
    ./modules.nix
    ./packages.nix
    ./services.nix
  ] ++ (import ../../../modules/home-manager);
  xdg.enable = true;

  home = {
    username = "datahearth";
    homeDirectory = "/home/datahearth";
    stateVersion = "24.11";
    sessionPath = [
      "$(go env GOBIN)"
      "$HOME/.cargo/bin"
    ];
  };
}
