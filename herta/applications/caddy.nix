{ pkgs, ... }:
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy;
  };
  networking.firewall.allowedTCPPorts = [
    443
    80
  ];
  networking.firewall.allowedUDPPorts = [
    443
  ];
}
