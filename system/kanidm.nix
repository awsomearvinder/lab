{pkgs, ...}: {
  services.kanidm = {
    enableServer = true;
    serverSettings = {
      origin = "https://idm.public.arvinderd.com";
      domain = "idm.public.arvinderd.com";
      ldapbindaddress = "[::1]:636";
      bindaddress = "[::1]:8443";
      trust_x_forward_for = true;
      tls_key = "/var/lib/acme/idm.public.arvinderd.com/key.pem";
      tls_chain = "/var/lib/acme/idm.public.arvinderd.com/fullchain.pem";
    };
  };
  systemd.services.kanidm.serviceConfig.BindReadOnlyPaths = [
    "/nix/store"
    "-/etc/resolv.conf"
    "-/etc/nsswitch.conf"
    "-/etc/hosts"
    "-/etc/localtime"
    "-/etc/kanidm"
    "-/etc/static/kanidm"
    "-/etc/ssl"
    "-/etc/static/ssl"
    "-/var/lib/acme/idm.public.arvinderd.com"
  ];
  services.caddy = {
    enable = true;
    virtualHosts = {
      "idm.public.arvinderd.com" = {
        extraConfig = ''
          reverse_proxy https://[::1]:8443 {
            header_up Host "idm.public.arvinderd.com:8443"
            transport http {
              tls
              tls_insecure_skip_verify
            }
          }
        '';
        useACMEHost = "idm.public.arvinderd.com";
      };
      "http://idm.public.arvinderd.com" = {
        extraConfig = "
        handle_path /.well-known/acme-challenge/* {
          root * /var/lib/acme/.challenges/.well-known/acme-challenge
          file_server
        }
        ";
      };
    };
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "ArvinderDhan@gmail.com";

  security.acme.certs."idm.public.arvinderd.com" = {
    webroot = "/var/lib/acme/.challenges";
    # Ensure that the web server you use can read the generated certs
    # Take a look at the group option for the web server you choose.
    group = "idm";
  };

  # /var/lib/acme/.challenges must be writable by the ACME user
  # and readable by the Nginx user. The easiest way to achieve
  # this is to add the Nginx user to the ACME group.
  users.groups.idm = {
    name = "idm";
    members = ["kanidm" "caddy"];
  };
  networking.firewall = {
    allowedTCPPorts = [443 80];
  };
}
