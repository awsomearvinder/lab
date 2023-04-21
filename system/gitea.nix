{...}: {
  services.gitea = {
    enable = true;
    rootUrl = "https://git.public.arvinderd.com";
    settings = {
      session.COOKIE_SECURE = true;
    };
    domain = "git.public.arvinderd.com";
    httpAddress = "::1";
  };
  services.caddy = {
    enable = true;
    virtualHosts = {
      "git.public.arvinderd.com" = {
        extraConfig = "reverse_proxy [::1]:3000";
      };
    };
  };
}
