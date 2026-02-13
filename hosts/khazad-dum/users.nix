{ pkgs, ... }:
{
  users = {
    defaultUserShell = pkgs.zsh;
    users.root.hashedPassword = "$y$j9T$BKXEiV67eSZOQBvDkQyNt0$pD1wI1XnmEZ3H/XyE8.ywg6MbX0fg82vKWT9L2yZx.2";
    users.datahearth = {
      useDefaultShell = true;
      isNormalUser = true;
      description = "Antoine Langlois";
      hashedPassword = "$y$j9T$CU51P3F9VUUoDPNZc1QK8/$44k3N0Qmn0PfQko1fWzt98C5aXKM/D.H2hLal.2KSK2";
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
    users.root = import ./home-manager/root.nix;
  };
}
