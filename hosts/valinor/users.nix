{ pkgs, config, ... }:
{
  users = {
    defaultUserShell = pkgs.zsh;
    motd = ''
       __     __    _ _                  
       \ \   / /_ _| (_)_ __   ___  _ __ 
        \ \ / / _` | | | '_ \ / _ \| '__|
         \ V / (_| | | | | | | (_) | |   
          \_/ \__,_|_|_|_| |_|\___/|_|   

      Bienvenue à Valinor,
      où la lumière des Deux Arbres brille éternellement,
      et les échos des chants anciens emplissent l'air.

      Ici, sous les étoiles scintillantes,
      que votre chemin soit guidé par la sagesse et la paix.

      « Dans ce royaume de beauté,
      chaque voyage est un nouveau récit en attente d'être raconté. »

      ----------------------------------------------------
    '';

    users = {
      ggau = {
        useDefaultShell = true;
        isNormalUser = true;
        description = "Germain Gau access account";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsI1zpu+UKBIl6s8+Meca8ZtiGH3zG8cqpaEqnT4Lb8"
        ];
      };
      datahearth = {
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
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { };
    users.datahearth = import ./home-manager/home.nix;
  };
}
