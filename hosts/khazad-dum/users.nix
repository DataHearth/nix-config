{ pkgs, ... }:
{
  users = {
    defaultUserShell = pkgs.zsh;
    users.datahearth = {
      useDefaultShell = true;
      isNormalUser = true;
      description = "Antoine Langlois";
      extraGroups = [
        "wheel"
        "docker"
        "networkmanager"
      ];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.datahearth = import ./home.nix;
  };
}
