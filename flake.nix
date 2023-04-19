{
  description = "A very basic flake";

  outputs = {
    self,
    nixpkgs,
  }: {
    nixosConfigurations.lab = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./system/configuration.nix
      ];
    };
  };
}
