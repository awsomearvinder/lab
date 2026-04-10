{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable-small";
    impermanence.url = "github:nix-community/impermanence";
    agenix.url = "github:ryantm/agenix";
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
  };

  outputs =
    {
      self,
      nixpkgs,
      impermanence,
      agenix,
      proxmox-nixos,
      vpn-confinement,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.opentofu
          pkgs.incus
          pkgs.just
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
            vpn-confinement.nixosModules.default
            impermanence.nixosModules.impermanence
            agenix.nixosModules.default
            proxmox-nixos.nixosModules.proxmox-ve
            (
              { pkgs, lib, ... }:
              {
                nixpkgs.overlays = [
                  proxmox-nixos.overlays.${system}
                ];
              }
            )
          ];
        };
      nixosConfigurations.herta = nixpkgs.lib.nixosSystem {
        modules = [
          ./herta/configuration.nix
          agenix.nixosModules.default
        ];
      };
    };
}
