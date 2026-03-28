let
  bender = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILNQHSuX71ZhzbtkBZV4RCHBdfZ+JUIR1hKfB9gRzlDE";

  jingliu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMPhNxZ3kPm1lIdfWv1ZNeiD3bbZ7O7EDCFP64HXKFvV";
  herta = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVu0peUl8J72Wd+bDbEtnvrAin0byGxZnVItlooh9tw";
in
{
  "oinkKeyFile.age".publicKeys = [
    jingliu
    bender
    herta
  ];
  "oinkSecretKeyFile.age".publicKeys = [
    jingliu
    bender
    herta
  ];
  "technitium-admin-pass.age".publicKeys = [
    bender
    jingliu
  ];
  "ldap-default-pass.age".publicKeys = [
    bender
    herta
  ];
  "pocket-ldap-password.age".publicKeys = [
    bender
    herta
  ];
  "lldap-env.age".publicKeys = [
    bender
    herta
  ];
}
