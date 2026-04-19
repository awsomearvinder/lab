{ config, ... }:
{
  networking.hostName = "seele";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.120.3.4";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway.address = "10.120.3.1";
  networking.nameservers = [ "10.120.3.1" ];
  services.jellyfin = {
    enable = true;
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/jellyfin/media 0755 ${config.services.jellyfin.user} ${config.services.jellyfin.group} -"
  ];
  services.caddy = {
    enable = true;
    acmeCA = "https://bronya.arvinderd.com/acme/ACME/directory";
    openFirewall = true;
    virtualHosts = {
      "video.seele.arvinderd.com" = {
        extraConfig = ''
          reverse_proxy "http://localhost:8096" {
            
          }
        '';
      };
    };
  };
  system.stateVersion = "26.05";
}
