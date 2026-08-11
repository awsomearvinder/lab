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
    "d /srv/minecraft/reclamation 0755 root root -"
    "d /srv/minecraft/integrated_mc 0755 root root -"
    "d /srv/minecraft/gtnh 0755 root root -"
  ];
  virtualisation.oci-containers.containers.society-sunlit-valley = {
    image = "docker.io/itzg/minecraft-server:java17";
    volumes = [
      "/srv/minecraft/society-sunlit-valley:/data:rw"
      "${config.age.secrets.CF_API_KEY.path}:/cf.key:ro"
    ];
    autoStart = false;
    ports = [
      "25566:25565"
    ];
    environment = {
      EULA = "TRUE";
      MAX_MEMORY = "16G";
      TZ = "America/Chicago";
      TYPE = "AUTO_CURSEFORGE";
      DIFFICULTY = "normal";
      USE_SIMD_FLAGS = "TRUE";
      ENABLE_WHITELIST = "TRUE";
      WHITELIST = "John_Benber,xXScam42069Xx";
      CF_SLUG = "society-sunlit-valley";
      CF_FILE_ID = "7907890";
      CF_API_KEY_FILE = "/cf.key";
      CF_FORCE_INCLUDE_MODS = "particular-reforged";
      CF_FORCE_SYNCHRONIZE = "TRUE";
      VERSION = "1.20.1";
    };
  };
  virtualisation.oci-containers.containers.gtnh = {
    image = "docker.io/itzg/minecraft-server:java25";
    volumes = [
      "/srv/minecraft/gtnh:/data:rw"
    ];
    ports = [
      "25567:25565"
    ];
    environment = {
      EULA = "TRUE";
      MAX_MEMORY = "10G";
      TZ = "America/Chicago";
      TYPE = "GTNH";
      GTNH_PACK_VERSION = "2.8.4";
      USE_SIMD_FLAGS = "TRUE";
      ENABLE_WHITELIST = "TRUE";
      WHITELIST = "John_Benber,xXScam42069Xx,javierhernan,ExtremeDoom";
      OPS = "javierhernan,John_Benber,ExtremeDoom";
      JVM_DD_OPTS = "fml.queryResult:confirm";
    };
  };
  networking.firewall.allowedTCPPorts = [
    25565
    25566
    25567
  ];
  virtualisation.oci-containers.containers.integrated_mc = {
    image = "docker.io/itzg/minecraft-server:java17";
    volumes = [
      "/srv/minecraft/integrated_mc:/data:rw"
      "${config.age.secrets.CF_API_KEY.path}:/cf.key:ro"
    ];
    ports = [
      "25565:25565"
    ];
    environment = {
      EULA = "TRUE";
      MAX_MEMORY = "10G";
      TZ = "America/Chicago";
      TYPE = "AUTO_CURSEFORGE";
      DIFFICULTY = "normal";
      USE_SIMD_FLAGS = "TRUE";
      ENABLE_WHITELIST = "TRUE";
      WHITELIST = "John_Benber,xXScam42069Xx,IMM3RSIVE,9rtyt,Geigus,ssommerai,sekahauwu,KattmannPlayzz,Oohaha1";
      OPS = "John_Benber";
      CF_SLUG = "integrated-minecraft";
      CF_FILE_ID = "7926313";
      CF_API_KEY_FILE = "/cf.key";
      CF_FORCE_INCLUDE_MODS = "particular-reforged,status-effect-bars-reforged";
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
