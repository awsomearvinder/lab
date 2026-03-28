{ pkgs, ... }:
{
  virtualisation.incus = {
    enable = true;
    ui.enable = true;
    package = pkgs.incus;
    preseed = {
      config = {
        "core.https_address" = "localhost:1320";
        "core.https_trusted_proxy" = "127.0.0.1";
        "oidc.client.id" = "2ebb0267-64ea-4b4d-8512-b71faf7fb771";
        "oidc.issuer" = "https://oidc.herta.arvinderd.com";
        "oidc.scopes" = "openid, email, profile";
        "oidc.claim" = "sub";
      };
    };
  };
  services.caddy.virtualHosts."incus.herta.arvinderd.com".extraConfig =
    "reverse_proxy https://localhost:1320 {
      transport http {
        tls
        tls_insecure_skip_verify
      }
      header_up Host incus.herta.arvinderd.com
    }";
}
