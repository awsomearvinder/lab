{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    hosts = (pkgs.formats.yaml {}).generate "hosts.yaml" {
      routers = {
        hosts = {
          router_main = {
            ansible_host = "192.168.2.1";
            ansible_user = "vyos";
            ansible_network_os = "vyos";
            ansible_connection = "network_cli";
          };
          bootstrap_vm = {
            ansible_host = "192.168.2.82";
            ansible_user = "bender";
          };
        };
      };
    };
  in {
    devShell.${system} = pkgs.mkShell {
      ANSIBLE_INVENTORY = "${hosts}";
      packages = [
        pkgs.ansible
      ];
    };
  };
}
