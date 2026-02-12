{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.zsh;
in
{
  options.home_modules.zsh = {
    enable = lib.mkEnableOption "zsh with oh-my-zsh and plugins";

    extraAliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra shell aliases to add";
    };

    extraPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Extra zsh plugins to add";
    };

    initContent = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra content for zsh init";
    };

    envExtra = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra environment content";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh.enable = true;

      plugins =
        [
          {
            name = "zsh-autopair";
            src = pkgs.zsh-autopair;
            file = "share/zsh/zsh-autopair/autopair.zsh";
          }
        ]
        ++ cfg.extraPlugins;

      shellAliases = {
        cat = "bat";
        cd = "z";
      } // cfg.extraAliases;

      initContent = lib.mkIf (cfg.initContent != "") cfg.initContent;
      envExtra = lib.mkIf (cfg.envExtra != "") cfg.envExtra;
    };
  };
}
