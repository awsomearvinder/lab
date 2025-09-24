{ ... }:
{
  networking.firewall.allowedTCPPorts = [
    6443
  ];
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.extraFlags = toString [
    "--debug"
    "--tls-san kafka.arvinderd.com"
    "--disable servicelb"
    "--disable traefik"
  ];
}
