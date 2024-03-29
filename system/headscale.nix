{...}: {
  sops.secrets."headscale/oauth-secret" = {
    mode = "0440";
    owner = "headscale";
  };
  services.headscale = {
    enable = true;
      address = "[::1]";
      port = 7940;
    settings = {
      tls_key_path = "/var/lib/acme/headscale.public.arvinderd.com/key.pem";
      tls_cert_path = "/var/lib/acme/headscale.public.arvinderd.com/cert.pem";
      server_url = "https://headscale.public.arvinderd.com";
      oidc = {
        issuer = "https://idm.public.arvinderd.com/oauth2/openid/headscale";
        client_id = "headscale";
        client_secret_path = "/run/secrets/headscale/oauth-secret";
      };
      derp = {
        server = {
          enabled = true;
          region_id = 999; # no clue what this actually does.

          region_code = "headscale";
          region_name = "headscale embedded derp";

          stun_listen_addr = "[::]:3478";
        };
        urls = [];
      };
    };
  };
  services.caddy = {
    enable = true;
    virtualHosts = {
      "headscale.public.arvinderd.com" = {
        extraConfig = ''
          reverse_proxy https://[::1]:7940 {
            header_up Host "headscale.arvinderd.com:7940"
            transport http {
              tls
              tls_insecure_skip_verify
            }
          }
        '';
        useACMEHost = "headscale.public.arvinderd.com";
      };
      "http://headscale.public.arvinderd.com" = {
        extraConfig = ''
          handle_path /.well-known/acme-challenge/* {
            root * /var/lib/acme/.challenges/.well-known/acme-challenge
            file_server
          }
        '';
      };
    };
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "ArvinderDhan@gmail.com";
  security.acme.certs."headscale.public.arvinderd.com" = {
    webroot = "/var/lib/acme/.challenges";
    group = "headscale";
  };
  users.groups.headscale = {
    name = "headscale";
    members = ["headscale" "caddy"];
  };
  networking.firewall = {
    allowedTCPPorts = [443 80];
    allowedUDPPorts = [3478];
  };
}
