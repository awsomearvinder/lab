{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ];
  services.paperless = {
    enable = true;
    domain = "paper.jingliu.arvinderd.com";
    environmentFile = config.age.secrets.paperless_env.path;
    settings = {
      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      PAPERLESS_SOCIAL_AUTO_SIGNUP = true;
      PAPERLESS_SOCIALACCOUNT_ALLOW_SIGNUPS = true;
      PAPERLESS_URL = "https://paper.jingliu.arvinderd.com";
    };
  };

  age.secrets.paperless_env.file = ../../secrets/paperless.env.age;
  age.secrets.paperless_env.owner = config.services.paperless.user;

  services.caddy.virtualHosts."paper.jingliu.arvinderd.com".extraConfig = ''
    reverse_proxy http://127.0.0.1:28981 {
      
    }
  '';
  environment.persistence."/persist".directories = [
    {
      directory = "/var/lib/paperless";
      user = config.services.paperless.user;
    }
  ];
}
