{ lib, ... }:
{
  imports = [
    ./ddns.nix
  ];

  networking.domain = lib.mkDefault "arvinderd.com";
}
