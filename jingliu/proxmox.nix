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

  # todo, use systemd-networkd
  # todo: don't use the same fucking network for both the host and the VMs
  # :/
  services.proxmox-ve.bridges = [ "vmbr0" ];
  networking.bridges.vmbr0.interfaces = [ "eno1" ];
  networking.interfaces.vmbr0.useDHCP = true;
  networking.interfaces.vmbr0.ipv4.addresses = [
    {
      address = "10.120.1.101";
      prefixLength = 24;
    }
  ];
}
