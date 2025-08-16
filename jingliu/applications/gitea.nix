{ pkgs, config, ... }:
{
  imports = [ ];
  services.gitea = {
    enable = true;
    stateDir = "/var/lib/gitea";
    dump.type = "tar.zst";
    lfs.enable = true;
    settings.service.DISABLE_REGISTRATION = true;
    settings.oauth2_client.REGISTER_EMAIL_CONFIRM = false;
    settings.oauth2_client.ENABLE_AUTO_REGISTRATION = true;
    # settings.oauth2.JWT_SECRET_URI = "file:/${config.services.gitea.customDir}/conf/oauth2_jwt_secret";
    # settings.server.LFS_JWT_SECRET_URI = "file:/${config.services.gitea.customDir}/conf/lfs_jwt_secret";
    # settings.security.INTERNAL_TOKEN_URI = "file:/${config.services.gitea.customDir}/conf/internal_token";
    # settings.security.SECRET_KEY_URI = "file:/${config.services.gitea.customDir}/conf/secret_key";
    settings.server.DOMAIN = "git.jingliu.arvinderd.com";
    settings.server.PROTOCOL = "http+unix";
    settings.session.COOKIE_SECURE = true;
    settings.server.ROOT_URL = "https://${config.services.gitea.settings.server.DOMAIN}";
  };
  age.secrets.gitea_oauth2_secret.file = ../../secrets/git-oauth2-secret.age;
  age.secrets.gitea_oauth2_secret.owner = config.services.gitea.user;
  age.secrets.gitea_oauth2_secret.group = config.services.gitea.group;

  services.caddy.virtualHosts."git.jingliu.arvinderd.com".extraConfig = ''
    reverse_proxy unix//run/gitea/gitea.sock {
    }
  '';

  environment.persistence."/persist".directories = [
    {
      directory = "/var/lib/gitea";
      user = config.services.gitea.user;
      group = config.services.gitea.group;
    }
  ];

  systemd.services.provision-gitea =
    let
      app_name = "pocket";
      oauth_provider = "openidConnect";
      key = "0e317fa5-5133-40a1-8424-eeec8b41b093";
      secret_file = config.age.secrets.gitea_oauth2_secret.path;

      gitea_cmd = "${pkgs.gitea}/bin/gitea --config ${config.services.gitea.customDir}/conf/app.ini";

      gitea_auth_command = cmd: ''
        ${cmd} \
                --name '${app_name}' \
                --provider '${oauth_provider}' \
                --key '${key}' \
                --secret "$(cat '${secret_file}')" \
                --scopes "openid email profile groups" \
                --auto-discover-url ${config.services.pocket-id.settings.APP_URL}/.well-known/openid-configuration \
                --admin-group gitea-admin \
                --group-claim-name "groups"'';
      provision_script = pkgs.writeShellScriptBin "gitea-provision.sh" ''
        #!/${pkgs.bash}/bin/bash

        # if it's conflicting, grab the name.
        name=$(${gitea_auth_command "${gitea_cmd} admin auth add-oauth"} \
          2>&1 \
          | ${pkgs.gnused}/bin/sed -s 's/.*\[.*:\s*//g' \
          | ${pkgs.gnused}/bin/sed -s 's/\s*\]//g')

        if [ $? -ne 0 ]; then
          id=$(${gitea_cmd} admin auth list | ${pkgs.gawk}/bin/awk 'NR > 1 { print $1 }')
          ${gitea_auth_command "${gitea_cmd} admin auth update-oauth"} \
            --id $id
        fi
      '';
    in
    {
      enable = true;
      serviceConfig = {
        Type = "oneshot";
        User = "${config.services.gitea.user}";
        ExecStart = "${provision_script}/bin/gitea-provision.sh";
      };
      wantedBy = [ "gitea.service" ];
    };
}
