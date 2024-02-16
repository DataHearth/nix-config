{ ... }:
{
  programs.waybar = {
    enable = true;
    style = builtins.readFile ./style.css;
  };
  home.file = {
    ".config/waybar/cava.sh".source = ./cava.sh;
    ".config/waybar/config".source = ./waybar.json;
    ".config/waybar/modules.json".source = ./modules.json;
  };
}
