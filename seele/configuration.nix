{ ... }:
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
  services.caddy = {
    enable = true;
    acmeCA = "https://bronya.arvinderd.com/acme/ACME/directory";
    openFirewall = true;
    virtualHosts = {
      "test.seele.arvinderd.com" = {
        extraConfig = ''
          respond / "woah" 200
        '';
      };
    };
  };
  system.stateVersion = "26.05";
}
