{ ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      import = [
        (builtins.fetchurl {
          url = "https://raw.githubusercontent.com/catppuccin/alacritty/832787d6cc0796c9f0c2b03926f4a83ce4d4519b/catppuccin-macchiato.toml";
          sha256 = "1iq187vg64h4rd15b8fv210liqkbzkh8sw04ykq0hgpx20w3qilv";
        })
      ];
      env.TERM = "xterm-256color";
      font = {
        size = 12;
        normal = {
          family = "FiraCode Nerd Font";
          style = "Retina";
        };
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
      window = {
        opacity = 0.9;
      };
    };
  };
}
