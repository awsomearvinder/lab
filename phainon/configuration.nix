{ config, ... }:
{
  imports = [
    ../lib/base.nix
  ];
  networking.hostName = "phainon";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.120.3.2";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway.address = "10.120.3.1";
  networking.nameservers = [ "10.120.3.1" ];
  nixpkgs.config.allowUnfree = true;
  systemd.tmpfiles.rules = [
    "d /srv/minecraft/society-sunlit-valley 0755 root root -"
  ];
  virtualisation.oci-containers.containers.society-sunlit-valley = {
    image = "itzg/minecraft-server:java17";
    volumes = [
      "/srv/minecraft/society-sunlit-valley:/data:rw"
      "${config.age.secrets.CF_API_KEY.path}:/cf.key:ro"
    ];
    ports = [
      "25565:25565"
    ];
    environment = {
      EULA = "TRUE";
      MAX_MEMORY = "16G";
      TZ = "CST";
      TYPE = "AUTO_CURSEFORGE";
      DIFFICULTY = "normal";
      USE_SIMD_FLAGS = "TRUE";
      ENABLE_WHITELIST = "TRUE";
      WHITELIST = "John_Benber";
      CF_SLUG = "society-sunlit-valley";
      CF_FILE_ID = "7907890";
      CF_API_KEY_FILE = "/cf.key";
      CF_FORCE_INCLUDE_MODS = "particular-reforged";
      CF_FORCE_SYNCHRONIZE = "TRUE";
      VERSION = "1.20.1";
    };
  };
  age.secrets.CF_API_KEY.file = ../secrets/CF_API_KEY.age;
  age.secrets.CF_API_KEY.owner = "root";
  age.secrets.CF_API_KEY.group = "root";
  age.secrets.CF_API_KEY.mode = "444";
  system.stateVersion = "26.05";
}
