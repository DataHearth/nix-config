{ ... }:
{
  programs.git = {
    enable = true;
    aliases = {
      co = "checkout";
      p = "push";
      a = "add";
      c = "commit";
      s = "status";
      pu = "pull";
      logs = "log --graph --oneline";
      remote-update = "remote update origin --prune";
    };
    difftastic.enable = true;
    lfs.enable = true;
    signing = {
      signByDefault = true;
    };
    userEmail = "dev@antoine-langlois.net";
    userName = "DataHearth";
    extraConfig = {
      init.defaultBranch = "main";
      safe.directory = [ "/etc/nixos" ];
    };
  };
}
