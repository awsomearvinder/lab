{ config, ... }:
{
  imports = [

  ];

  services.vikunja.enable = true;
  services.vikunja.frontendScheme = "https";
  services.vikunja.frontendHostname = "vikunja.jingliu.arvinderd.com";
  services.vikunja.database.path = "/var/lib/private/vikunja/vikunja.db";
  services.vikunja.port = 4183;
  services.vikunja.settings = {
    service.enableregistration = false;
    service.unixsocket = "/run/vikunja/vikunja.sock";
    # This is terrible and should be fixed at some point, but I'm a
    # lazy bastard.
    service.timezone = "America/Chicago";
    service.unixsocketmode = "0o666";
    ratelimit.enabled = true;
    ratelimit.limit = 500;
    auth.openid = {
      enabled = true;
      providers = {
        pocket = {
          name = "pocket";
          authurl = "https://oidc.jingliu.arvinderd.com";
          clientid = "90ec9861-6c2d-4df0-8312-d36ae89a7123";
          scope = "openid profile email";
        };
      };
    };
    mailer = {
      enabled = true;
      host = "smtp.fastmail.com";
      username = "personal@mail.arvinderd.com";
      fromemail = "vikunja@mail.arvinderd.com";
      forcessl = true;
      port = 465;
    };
  };
  systemd.services.vikunja.serviceConfig.RuntimeDirectory = "vikunja";

  age.secrets.vikunjaSecrets.file = ../../secrets/vikunjaSecrets.age;
  services.vikunja.environmentFiles = [
    config.age.secrets.vikunjaSecrets.path
  ];
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/private/vikunja"
    ];
  };
  services.caddy.virtualHosts."vikunja.jingliu.arvinderd.com" = {
    extraConfig = ''
      reverse_proxy unix//run/vikunja/vikunja.sock {
        
      }
    '';
  };
}
