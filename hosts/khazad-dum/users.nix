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
        "libvirtd"
        "networkmanager"
      ];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.datahearth = import ./home-manager/home.nix;
  };
}
