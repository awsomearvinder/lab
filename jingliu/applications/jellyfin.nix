{ config, pkgs, ... }:
{

  services.jellyfin = {
    enable = true;
    dataDir = "/var/lib/jellyfin/data";
    cacheDir = "/var/lib/jellyfin/cache";
    configDir = "/var/lib/jellyfin/config";
  };

  services.caddy.virtualHosts."video.jingliu.arvinderd.com".extraConfig = ''
    reverse_proxy http://[::1]:8096 {
    }
  '';

  users.users.jellyfin = {
    # isNormalUser = true;
    uid = 100001;
    group = "jellyfin";
    extraGroups = [ "video" ];
  };
  users.groups.jellyfin = {
    gid = 100001;
  };

  environment.persistence."/persist" = {
    directories = [
      {
        directory = "/var/lib/jellyfin/config";
        user = "jellyfin";
        group = "jellyfin";
        mode = "0755";
      }
      {
        directory = "/var/lib/jellyfin/cache";
        user = "jellyfin";
        group = "jellyfin";
        mode = "0755";
      }
      {
        directory = "/var/lib/jellyfin/media";
        user = "jellyfin";
        group = "jellyfin";
        mode = "0755";
      }
      {
        directory = "/var/lib/jellyfin/data";
        user = "jellyfin";
        group = "jellyfin";
        mode = "0755";
      }
    ];
    files = [
      "/var/lib/jellyfin/web-config.json"
    ];
  };
}
