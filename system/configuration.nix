{...}: {
  imports = [
    ./hardware-configuration.nix
    ./kanidm.nix
    ./gitea.nix
    ./headscale.nix
  ];

  sops.defaultSopsFile = ../secrets/lab.yaml;
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 30d";
  };

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = false;
  networking.hostName = "linode-nixos";
  networking.tempAddresses = "disabled";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbJuiw1aOPykLtDP2hQCEifKP2QBwh+wJ0ktYjv6S7P bender@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIelQTt1o9ZWEx5ZODwum+r7m382aJP/gOTopyPiVKMK root@linode-nixos" # CI
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMztLpThvXPu85+kGuD/OVdpUNAXbPpYtcPUIyU96PU1 bender@bender_desktop" # windows desktop
  ];
  system.stateVersion = "23.05";
}
