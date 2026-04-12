let
  bender = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILNQHSuX71ZhzbtkBZV4RCHBdfZ+JUIR1hKfB9gRzlDE";

  jingliu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMPhNxZ3kPm1lIdfWv1ZNeiD3bbZ7O7EDCFP64HXKFvV";
  herta = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVu0peUl8J72Wd+bDbEtnvrAin0byGxZnVItlooh9tw";
  phainon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN0X+WEnvBOnVEhi7CbyaQnuNDNYhzHk1rIF1JHCSWzE";
  bronya = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG87YNObxs/1xHyo0vLlJdlrUHfyOgJrgrJhyfefA7yX bender@desktop";
in
{
  "oinkKeyFile.age".publicKeys = [
    jingliu
    bender
    herta
    phainon
    bronya
  ];
  "oinkSecretKeyFile.age".publicKeys = [
    jingliu
    bender
    herta
    phainon
    bronya
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
  "CF_API_KEY.age".publicKeys = [
    bender
    phainon
  ];
  "root_ca.crt".publicKeys = [
    bender
    bronya
  ];
  "intermediate.crt".publicKeys = [
    bender
    bronya
  ];
  "intermediate.key".publicKeys = [
    bender
    bronya
  ];
  "step.password".publicKeys = [
    bender
    bronya
  ];
}
