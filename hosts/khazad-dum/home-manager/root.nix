{
  imports = [ ] ++ (import ../../../modules/home-manager);

  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "25.11";
  };

  home_modules = {
    neovim = {
      enable = true;
      defaultEditor = true;
    };

    zsh.enable = true;
    bat.enable = true;
  };

  programs = {
    btop.enable = true;
    ripgrep.enable = true;
    fd.enable = true;
    jq.enable = true;
  };
}
