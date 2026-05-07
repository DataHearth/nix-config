{ pkgs, lib }:
{
  lsp = import ./lsps.nix { inherit pkgs; };
}
