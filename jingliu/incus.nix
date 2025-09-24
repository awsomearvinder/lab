{ ... }:
{
  virtualisation.incus = {
    enable = true;
    ui.enable = true;
    preseed = {
      config = {
        "core.https_address" = "[::1]:9030";
        "core.https_trusted_proxy" = "[::1]";
        "images.auto_update_interval" = 6;
        "oidc.client.id" = "2ebb0267-64ea-4b4d-8512-b71faf7fb771";
        "oidc.issuer" = "https://oidc.jingliu.arvinderd.com";
        "oidc.scopes" = "openid,profile,email";
      };
      networks = [
        {
          name = "incusbr0";
          type = "bridge";
          config = {
            "ipv4.address" = "10.120.100.1/24";
            "ipv4.nat" = false;
          };
        }
      ];
      storage_pools = [
        {
          name = "default";
          driver = "dir";
          config = {
            source = "/persist/incus/datastore";
          };
        }
      ];
    };
  };

  services.caddy.virtualHosts."https://incus.jingliu.arvinderd.com".extraConfig = ''
    reverse_proxy https://localhost:9030 {
      transport http {
        tls
        tls_insecure_skip_verify
      }
    }
  '';
}
