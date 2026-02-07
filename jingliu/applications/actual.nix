{ config, pkgs, ... }:
{
  services.actual = {
    enable = true;
    user = "actual";
    group = "actual";
    settings.port = 3246;
    settings.hostname = "::1";
    settings.loginMethod = "openid";
    settings.allowedLoginMethods = [ "openid" ];
    settings.dataDir = "/persist/actual";
    settings.openId = {
      discoveryURL = "https://oidc.jingliu.arvinderd.com/.well-known/openid-configuration";
      client_id = "e4d1a86c-de96-4a9a-af27-4b14ec303523";
      client_secret._secret = config.age.secrets.actual_client_secret.path;
      server_hostname = "https://finance.jingliu.arvinderd.com";
      authMethod = "openid";
    };
  };
  systemd.services.actual.environment = {
    ACTUAL_USER_CREATION_MODE = "login";
  };
  users.users.actual.enable = true;
  users.users.actual.group = "actual";
  users.users.actual.isSystemUser = true;
  users.groups.actual = { };

  age.secrets.actual_client_secret.file = ../../secrets/actual-secret.age;
  age.secrets.actual_client_secret.group = config.services.actual.group;
  age.secrets.actual_client_secret.owner = config.services.actual.user;
  services.caddy.virtualHosts."finance.jingliu.arvinderd.com".extraConfig = ''
    reverse_proxy http://[::1]:3246 {
      
    }
  '';
}
