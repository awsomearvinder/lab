let
  bender = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILNQHSuX71ZhzbtkBZV4RCHBdfZ+JUIR1hKfB9gRzlDE";

  jingliu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMPhNxZ3kPm1lIdfWv1ZNeiD3bbZ7O7EDCFP64HXKFvV";
  kafka = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINwkOkbrOPNVqGh6Ng6J4OTxVsPut18hJa83EBHRRPo8";
in
{
  "git-oauth2-secret.age".publicKeys = [
    jingliu
    bender
  ];
  "oinkKeyFile.age".publicKeys = [
    jingliu
    bender
    kafka
  ];
  "oinkSecretKeyFile.age".publicKeys = [
    jingliu
    bender
    kafka
  ];
  "technitium-admin-pass.age".publicKeys = [
    bender
    jingliu
  ];
  "ldap-default-pass.age".publicKeys = [
    bender
    jingliu
  ];
  "vikunjaSecrets.age".publicKeys = [
    bender
    jingliu
  ];
  "pocket-ldap-password.age".publicKeys = [
    bender
    jingliu
  ];
  "lldap-env.age".publicKeys = [
    bender
    jingliu
  ];
  "actual-secret.age".publicKeys = [
    bender
    jingliu
  ];
}
