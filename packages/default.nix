{ pkgs }:
{
  f5vpn = pkgs.callPackage ./f5vpn.nix { };
  f5epi = pkgs.callPackage ./f5epi.nix { };
  claude-code = pkgs.callPackage ./claude-code.nix { };
}
