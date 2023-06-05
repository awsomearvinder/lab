{
  description = "A very basic flake";

  inputs = {
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = {
    self,
    nixpkgs,
    sops-nix,
  }:
  let
    KANIDM_URL = "https://idm.public.arvinderd.com";
  in
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    nixosConfigurations.lab = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./system/configuration.nix
        sops-nix.nixosModules.sops
      ];
    };
    devShell.x86_64-linux = pkgs.mkShell {
      inherit KANIDM_URL;
      packages = [
        pkgs.kanidm
        pkgs.sops
      ];
    };
  };
}
