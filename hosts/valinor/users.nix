{ pkgs, ... }:
{
  users = {
    defaultUserShell = pkgs.bash;
    users = {
      datahearth = {
        shell = pkgs.zsh;
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
    motd = ''
       __     __    _ _                  
       \ \   / /_ _| (_)_ __   ___  _ __ 
        \ \ / / _` | | | '_ \ / _ \| '__|
         \ V / (_| | | | | | | (_) | |   
          \_/ \__,_|_|_|_| |_|\___/|_|   

      Welcome to Valinor,  
      where the light of the Two Trees shines eternally,  
      and the echoes of ancient songs fill the air.  

      Here, beneath the shimmering stars,  
      may your path be guided by wisdom and peace.  

      “In this realm of beauty,  
      every journey is a new tale waiting to be told.”  

      ----------------------------------------------------
    '';
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs =
      {
      };
    users = {
      "datahearth" = import ./home-manager/home.nix;
    };
  };
}
