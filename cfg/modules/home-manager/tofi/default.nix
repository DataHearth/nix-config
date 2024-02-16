{ ... }:
let 
  tofiConfig = ".config/tofi";
in
{
  home.file = {
    "${tofiConfig}/launcher.conf".source = ./launcher.conf;
    "${tofiConfig}/powermenu.conf".source = ./powermenu.conf;
    "${tofiConfig}/confirm.conf".source = ./confirm.conf;
    "${tofiConfig}/screenshot.conf".source = ./screenshot.conf;
    "${tofiConfig}/clipboard.conf".source = ./clipboard.conf;
    "${tofiConfig}/exec.sh".source = ./exec.sh;
  };
}
