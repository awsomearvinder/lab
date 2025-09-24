{ config, lib, ... }:
{
  services.lldap = {
    enable = true;
    settings = {
      ldap_user_email = "lab@mail.arvinderd.com";
      ldap_user_dn = "bender";
      ldap_base_dn = "dc=arvinderd, dc=com";
      http_host = "127.0.0.1";
      http_url = "https://lldap.jingliu.arvinderd.com";
      database_url = "sqlite://./lldap.db?mode=rwc";
      verbose = true;
      force_ldap_user_pass_reset = "always";
      ldaps_options.enabled = true;
      ldaps_options.cert_file = "/run/credentials/lldap.service/cert.pem";
      ldaps_options.key_file = "/run/credentials/lldap.service/key.pem";
      # TODO: SMTP
      smtp_options.server = "smtp.fastmail.com";
      smtp_options.port = 465;
      smtp_options.smtp_encryption = "TLS";
      smtp_options.from = "LLDAP <lldap@mail.arvinderd.com>";
      smtp_options.enable_password_reset = true;
    };
    environment = {
      # this is overwrote in the environmentFile
      LLDAP_LDAP_USER_PASS_FILE = "/run/credentials/lldap.service/lldap_admin_pass";
    };
    environmentFile = "${config.age.secrets.lldap_env.path}";
  };

  security.acme.acceptTerms = true;
  security.acme.certs."lldap.jingliu.arvinderd.com" = {
    reloadServices = [ "lldap" ];
  };
  security.acme.defaults.listenHTTP = ":9063";
  security.acme.defaults.email = "lab@mail.arvinderd.com";

  systemd.services.lldap.serviceConfig.LoadCredential = [
    "lldap_admin_pass:${config.age.secrets.lldap_admin_pass.path}"
    "cert.pem:${config.security.acme.certs."lldap.jingliu.arvinderd.com".directory}/cert.pem"
    "key.pem:${config.security.acme.certs."lldap.jingliu.arvinderd.com".directory}/key.pem"
  ];

  system.activationScripts."createPersistentStorageDirs".deps = [
    "var-lib-private-permissions"
    "users"
    "groups"
  ];
  system.activationScripts = {
    "var-lib-private-permissions" = {
      deps = [ "specialfs" ];
      text = ''
        mkdir -p /persist/var/lib/private
        chmod 0700 /persist/var/lib/private
      '';
    };
  };

  age.secrets.lldap_admin_pass.file = ../secrets/ldap-default-pass.age;
  age.secrets.lldap_admin_pass.owner = "${config.systemd.services.lldap.serviceConfig.User or "root"
  }";
  age.secrets.lldap_admin_pass.group = "${config.systemd.services.lldap.serviceConfig.Group or "root"
  }";
  age.secrets.lldap_env.file = ../secrets/lldap-env.age;

  services.caddy.virtualHosts."https://lldap.jingliu.arvinderd.com" = {
    extraConfig = ''
      reverse_proxy http://127.0.0.1:17170 {
        
      }
    '';
  };
  services.caddy.virtualHosts."http://lldap.jingliu.arvinderd.com" = {
    extraConfig = ''
      reverse_proxy http://127.0.0.1:9063 {
        
      }
    '';
  };

  services.pocket-id = {
    enable = true;
    settings.TRUST_PROXY = true;
    settings.APP_URL = "https://oidc.jingliu.arvinderd.com";
    settings.UNIX_SOCKET = "/run/${config.systemd.services.pocket-id.serviceConfig.RuntimeDirectory}/pocket.sock";
    settings.UNIX_SOCKET_MODE = "0766";
    settings.LDAP_ENABLED = true;
    settings.LDAP_URL = "ldaps://lldap.jingliu.arvinderd.com:6360";
    settings.LDAP_BIND_DN = "cn=pocketid,ou=people,dc=arvinderd,dc=com";
    settings.LDAP_BASE = "dc=arvinderd,dc=com";
    settings.LDAP_ATTRIBUTE_USER_UNIQUE_IDENTIFIER = "uuid";
    settings.LDAP_ATTRIBUTE_USER_USERNAME = "user_id";
    settings.LDAP_ATTRIBUTE_USER_EMAIL = "mail";
    settings.LDAP_ATTRIBUTE_USER_FIRST_NAME = "first_name";
    settings.LDAP_ATTRIBUTE_USER_LAST_NAME = "last_name";
    settings.LDAP_ATTRIBUTE_USER_PROFILE_PICTURE = "avatar";
    settings.LDAP_ATTRIBUTE_GROUP_UNIQUE_IDENTIFIER = "uuid";
    settings.LDAP_ATTRIBUTE_GROUP_NAME = "cn";
    settings.LDAP_ATTRIBUTE_ADMIN_GROUP = "pocket_admin";
    settings.UI_CONFIG_DISABLED = true;
    settings.SMTP_HOST = "smtp.fastmail.com";
    settings.SMTP_PORT = 465;
    settings.SMTP_FROM = "pocketid@mail.arvinderd.com";
    settings.SMTP_TLS = "tls";
    settings.EMAIL_ONE_TIME_ACCESS_AS_ADMIN_ENABLED = true;
    settings.EMAIL_ONE_TIME_ACCESS_AS_UNAUTHENTICATED_ENABLED = true;
    # settings.LDAP_BIND_PASSWORD_FILE doesn't work because agenix likes to create a '\n' at EOF
    # on decryption, and pocket-id sends that over to LDAP in authentication, lol.
    environmentFile = "${config.age.secrets.pocket_ldap_password.path}";
  };
  age.secrets.pocket_ldap_password.file = ../secrets/pocket-ldap-password.age;
  age.secrets.pocket_ldap_password.owner = "${config.services.pocket-id.user}";
  age.secrets.pocket_ldap_password.group = "${config.services.pocket-id.group}";

  services.caddy.virtualHosts."oidc.jingliu.arvinderd.com" = {
    extraConfig = ''
      reverse_proxy unix//run/${config.systemd.services.pocket-id.serviceConfig.RuntimeDirectory}/pocket.sock {
        
      }
    '';
  };

  systemd.services.pocket-id.serviceConfig = {
    RuntimeDirectory = lib.mkDefault "pocketid";
  };
  environment.persistence."/persist".directories = [
    {
      directory = "/var/lib/private/lldap";
      mode = "0700";
      user = config.systemd.services.lldap.serviceConfig.User;
      group = config.systemd.services.lldap.serviceConfig.Group;
    }
    {
      directory = "/var/lib/pocket-id";
      mode = "0700";
      user = config.services.pocket-id.user;
      group = config.services.pocket-id.group;
    }
    {
      directory = "/var/lib/acme";
      user = "acme";
      mode = "0700";
    }
  ];
}
