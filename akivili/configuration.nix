{ ... }: {
  networking.defaultGateway.address = "10.120.3.1";
  networking.nameservers = [ "10.120.3.1" ];
  networking.hostName = "akivili";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.120.3.5";
      prefixLength = 24;
    }
  ];
  nixpkgs.config.allowUnfree = true;
  services.omada = {
    enable = true;
    openFirewallDevicePorts = true;
    dataDir = "/var/lib/omada";
  };
  services.caddy = {
    enable = true;
    acmeCA = "https://bronya.arvinderd.com/acme/ACME/directory";
    openFirewall = true;
    virtualHosts = {
      "omada.akivili.arvinderd.com" = {
        extraConfig = ''
          reverse_proxy "https://localhost:8043" {
            transport http {
              tls
              tls_insecure_skip_verify
            }
          }
        '';
      };
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
    8043
  ];
  system.stateVersion = "26.11";
}
