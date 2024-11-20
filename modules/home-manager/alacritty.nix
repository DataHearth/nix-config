{ config, lib, ... }:
let
  cfg = config.hm.alacritty;

  enable = lib.mkEnableOption "alacritty";
  themes = lib.mkOption {
    type = lib.types.listOf lib.types.path;
    default = [ ];
    description = "List of themes to install";
    example = [
      (builtins.fetchurl {
        url = "https://example.com/theme.toml";
        sha256 = lib.fakeSha256;
      })
    ];
  };
  opacity = lib.mkOption {
    type = lib.types.float;
    default = 0.9;
    description = "Window opacity";
    example = 1.0;
  };
  fontSize = lib.mkOption {
    type = lib.types.int;
    default = 12;
    description = "Font size";
    example = 14;
  };
in
{
  options.hm.alacritty = {
    inherit
      enable
      themes
      opacity
      fontSize
      ;
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        general.import = [
          (builtins.fetchurl {
            url = "https://raw.githubusercontent.com/catppuccin/alacritty/832787d6cc0796c9f0c2b03926f4a83ce4d4519b/catppuccin-macchiato.toml";
            sha256 = "1iq187vg64h4rd15b8fv210liqkbzkh8sw04ykq0hgpx20w3qilv";
          })
        ] ++ cfg.themes;
        env.TERM = "xterm-256color";
        font = {
          size = cfg.fontSize;
          normal = {
            family = "Mononoki Nerd Font";
          };
        };
        scrolling.multiplier = 5;
        selection.save_to_clipboard = true;
        window = {
          opacity = cfg.opacity;
        };
      };
    };
  };
}
