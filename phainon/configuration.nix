{ pkgs, ... }:
{
  imports = [
    ../lib/base.nix
  ];
  networking.hostName = "phainon";
}
