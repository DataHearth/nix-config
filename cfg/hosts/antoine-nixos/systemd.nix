{pkgs, ...}: 
{
  # Fix autologin problem gnome https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 datahearth libvirtd -"
  ];
 }
