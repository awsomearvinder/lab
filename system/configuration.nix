{...}: {
  imports = [
    ./hardware-configuration.nix
    ./kanidm.nix
    ./gitea.nix
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = false;
  networking.hostName = "linode-nixos";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbJuiw1aOPykLtDP2hQCEifKP2QBwh+wJ0ktYjv6S7P bender@desktop"
  ];
}
