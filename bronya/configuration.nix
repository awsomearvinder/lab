{ config, ... }:
{
  imports = [
    ../lib/base.nix
  ];
  networking.hostName = "bronya";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.120.3.3";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway.address = "10.120.3.1";
  networking.nameservers = [ "10.120.3.1" ];
  age.secrets.root_ca.file = ../secrets/root_ca.crt;
  age.secrets.root_ca.owner = config.systemd.services."step-ca".serviceConfig.User;
  age.secrets.root_ca.group = config.systemd.services."step-ca".serviceConfig.Group;
  age.secrets.intermediate_cert.file = ../secrets/intermediate.crt;
  age.secrets.intermediate_cert.owner = config.systemd.services."step-ca".serviceConfig.User;
  age.secrets.intermediate_cert.group = config.systemd.services."step-ca".serviceConfig.Group;
  age.secrets.intermediate_key.file = ../secrets/intermediate.key;
  age.secrets.intermediate_key.owner = config.systemd.services."step-ca".serviceConfig.User;
  age.secrets.intermediate_key.group = config.systemd.services."step-ca".serviceConfig.Group;
  age.secrets.step_password.file = ../secrets/step.password;
  age.secrets.step_password.owner = config.systemd.services."step-ca".serviceConfig.User;
  age.secrets.step_password.group = config.systemd.services."step-ca".serviceConfig.Group;

  services.step-ca = {
    enable = true;
    address = "10.120.3.3";
    port = 443;
    openFirewall = true;
    intermediatePasswordFile = "${config.age.secrets.step_password.path}";
    settings = builtins.fromJSON ''
      {
      	"root": "${config.age.secrets.root_ca.path}",
      	"federatedRoots": null,
      	"crt": "${config.age.secrets.intermediate_cert.path}",
      	"key": "${config.age.secrets.intermediate_key.path}",
      	"address": ":443",
      	"insecureAddress": "",
      	"dnsNames": [
      		"arvinderd.com"
      	],
      	"logger": {
      		"format": "text"
      	},
      	"db": {
      		"type": "badgerv2",
      		"dataSource": "/var/lib/step-ca/db"
      	},
      	"authority": {
      		"provisioners": [
      			{
      				"type": "ACME",
      				"name": "acme"
      			}
      		]
      	},
      	"tls": {
      		"cipherSuites": [
      			"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256",
      			"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
      		],
      		"minVersion": 1.2,
      		"maxVersion": 1.3,
      		"renegotiation": false
      	}
      }
    '';
  };
}
