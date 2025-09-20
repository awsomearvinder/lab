{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    agenix.url = "github:ryantm/agenix";
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";
  };

  outputs =
    {
      self,
      nixpkgs,
      impermanence,
      agenix,
      proxmox-nixos,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      talm = pkgs.buildGoModule {
        name = "talm";
        vendorHash = "sha256-ykzJ2qt/ps+zpMd2g939CDV6qAfLbUD5ZhU0RAM/9Zw=";
        src = pkgs.fetchFromGitHub {
          owner = "cozystack";
          repo = "talm";
          rev = "v0.15.0";
          hash = "sha256-egTHXAUdzE7jRXQZ4JFYiOht6lWEiqY7ClQ9XdFJB8c=";
        };
      };
    in
    {

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          talm
        ];
      };

      nixosConfigurations.jingliu =
        let
          system = "x86_64-linux";
          # pkgs = import nixpkgs { inherit system; };
        in
        nixpkgs.lib.nixosSystem {
          modules = [
            ./jingliu/configuration.nix
            impermanence.nixosModules.impermanence
            agenix.nixosModules.default
            proxmox-nixos.nixosModules.proxmox-ve
            (
              { pkgs, lib, ... }:
              {
                nixpkgs.overlays = [ proxmox-nixos.overlays.${system} ];
              }
            )
          ];
        };
    };
}
