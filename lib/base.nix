{ lib, ... }:
{
  imports = [
    ./ddns.nix
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILNQHSuX71ZhzbtkBZV4RCHBdfZ+JUIR1hKfB9gRzlDE"
  ];
  networking.domain = lib.mkDefault "arvinderd.com";
}
