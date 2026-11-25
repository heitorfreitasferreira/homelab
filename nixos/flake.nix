{
  description = "Homelab: hosts NixOS declarados neste repo e aplicados pelo comin a cada push";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      disko,
      sops-nix,
      comin,
      ...
    }:
    let
      host =
        name: extra:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            comin.nixosModules.comin
            ./modules/base.nix
            ./hosts/${name}
          ]
          ++ extra;
        };
    in
    {
      nixosConfigurations.racknerd = host "racknerd" [ ];
      # Ensaio local da virada (nixos/README.md). Nunca aplicar no racknerd real.
      nixosConfigurations.racknerd-ensaio = host "racknerd" [ ./hosts/racknerd/ensaio.nix ];
    };
}
