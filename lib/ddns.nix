{ config, lib, ... }:
let
  cfg = config.custom.ddns;
in
{
  options = {
    custom.ddns.enable = lib.mkOption {
      default = true;
      description = "Enable DDNS for this server";
    };
    custom.ddns.hostname = lib.mkOption {
      default = "${config.networking.hostName}";
      description = ''
        Hostname to set DNS entries for.
      '';
    };
    custom.ddns.domain = lib.mkOption {
      default = "${config.networking.domain}";
      description = ''
        Domain to set DNS entries for.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    # required because oink doesn't support updating
    # only management / perm addresses.
    networking.tempAddresses = "disabled";
    services.oink = {
      enable = true;
      domains = [
        {
          domain = "${cfg.domain}";
          subdomain = "${config.networking.hostName}";
        }
        {
          domain = "${cfg.domain}";
          subdomain = "*.${config.networking.hostName}";
        }
      ];
      apiKeyFile = config.age.secrets.oinkKeyFile.path;
      secretApiKeyFile = config.age.secrets.oinkSecretKeyFile.path;
    };

    age.secrets.oinkKeyFile.file = ../secrets/oinkKeyFile.age;
    age.secrets.oinkKeyFile.owner = config.systemd.services.oink.user or "root";
    age.secrets.oinkKeyFile.group = config.systemd.services.oink.group or "root";
    age.secrets.oinkSecretKeyFile.file = ../secrets/oinkSecretKeyFile.age;
    age.secrets.oinkSecretKeyFile.owner = config.systemd.services.oink.user or "root";
    age.secrets.oinkSecretKeyFile.group = config.systemd.services.oink.group or "root";
  };
}
