{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    arctis-sound-manager = {
      url = "github:loteran/Arctis-Sound-Manager?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    arctis-sound-manager,
    ...
  }: let
    inherit (nixpkgs) lib;

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          self.overlays.default
        ];
      };

    mkNixos = system: modules:
      lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules =
          modules
          ++ [
            {
              nixpkgs.pkgs = mkPkgs system;

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                overwriteBackup = true;
                extraSpecialArgs = {inherit inputs;};

                users.tomalaci = {
                  imports = [
                    ./modules/home/home.nix
                  ];
                };
              };
            }
          ];
      };

    system = "x86_64-linux";
    pkgs = mkPkgs system;

  in {
    overlays.default = import ./modules/overlays/default.nix;

    nixosConfigurations = {
      desktop = mkNixos "x86_64-linux" [
        ./modules/hosts/desktop.nix
        ./modules/system/system.nix
        home-manager.nixosModules.home-manager
        arctis-sound-manager.nixosModules.default
      ];
    };

    homeConfigurations.tomalaci = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {inherit inputs;};
      modules = [
        ./modules/home/home.nix
      ];
    };

    formatter.${system} = pkgs.writeShellApplication {
      name = "alejandra-tree";
      runtimeInputs = [pkgs.alejandra];
      text = ''
        if [ "$#" -eq 0 ]; then
          exec alejandra .
        else
          exec alejandra "$@"
        fi
      '';
    };
  };
}
