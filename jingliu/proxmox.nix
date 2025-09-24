{ ... }:
{
  environment.persistence."/persist".directories = [
    "/var/lib/pve-cluster"
  ];
  services.proxmox-ve = {
    enable = true;
    ipAddress = "2601:447:d17f:7ae1:42a8:f0ff:fe23:c8e8";
  };
  services.caddy = {
    virtualHosts."proxmox.jingliu.arvinderd.com".extraConfig = ''
      reverse_proxy [::1]:8006 {
        header_up Host jingliu
        transport http {
          tls
          tls_insecure_skip_verify
        }
      }
    '';
  };

  services.proxmox-ve.bridges = [ "proxbr0" ];
}
