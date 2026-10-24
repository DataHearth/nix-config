{ pkgs }:
{
  f5vpn-ng = pkgs.callPackage ./f5vpn-ng.nix { };
  claude-desktop = pkgs.callPackage ./claude-desktop.nix { };
}
