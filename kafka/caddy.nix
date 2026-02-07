{ ... }:
{
  # todo: do dyndns or dns-01
  services.caddy = {
    enable = true;
    virtualHosts."test.kafka.arvinderd.com" = {
      extraConfig = ''
        reverse_proxy http://10.120.110.102:80
      '';
    };
    virtualHosts."grafana.kafka.arvinderd.com" = {
      extraConfig = ''
        reverse_proxy http://10.120.110.102:80
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [ 443 ];
}
