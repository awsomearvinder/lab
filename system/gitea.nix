{...}: {
  services.gitea = {
    enable = true;
    settings = {
      server = {
        ROOT_URL = "https://git.public.arvinderd.com";
        HTTP_ADDR = "::1";
        DOMAIN = "git.public.arvinderd.com";
      };
      session.COOKIE_SECURE = true;
      service.ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
    };
  };
  sops.secrets.woodpecker-env = {
    mode = "0444";
  };
  services.woodpecker-server = {
    enable = true;
    environment = {
      WOODPECKER_ADMIN = "administrator";
      WOODPECKER_OPEN = "true";
      WOODPECKER_GITEA = "true";
      WOODPECKER_GITEA_URL = "https://git.public.arvinderd.com";
      WOODPECKER_HOST = "https://ci.public.arvinderd.com";
      WOODPECKER_SERVER_ADDR = ":8091";
    };
    environmentFile = "/run/secrets/woodpecker-env";
  };
  services.woodpecker-agents.agents.default = {
    environment = {
      WOODPECKER_SERVER_ADDR = "https://ci.public.arvinderd.com:8091";
      WOODPECKER_HEALTHCHECK = "false";
    };
    enable = true;
    extraGroups = ["docker"];
    environmentFile = ["/run/secrets/woodpecker-env"];
  };
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  services.caddy = {
    enable = true;
    virtualHosts = {
      "git.public.arvinderd.com" = {
        extraConfig = "reverse_proxy [::1]:3000";
      };
      "ci.public.arvinderd.com" = {
        extraConfig = "reverse_proxy [::1]:8091";
      };
    };
  };
}
