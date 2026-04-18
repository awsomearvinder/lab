{
  config,
  pkgs,
  lib,
  ...
}:
let
  proxy_mapping = {
    "test" = "test.seele";
  };
in
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy;
    virtualHosts = lib.attrsets.concatMapAttrs (new_name: real_domain: {
      "${new_name}.${config.networking.hostName}.${config.networking.domain}" = {
        extraConfig = ''
          reverse_proxy https://${real_domain}.${config.networking.domain} {
            header_up Host Host ${real_domain}.${config.networking.domain}
          }
        '';
      };
    }) proxy_mapping;
  };
  networking.firewall.allowedTCPPorts = [
    443
    80
  ];
  networking.firewall.allowedUDPPorts = [
    443
  ];
}
