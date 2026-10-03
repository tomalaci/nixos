{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
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
    ...
  }: let
    inherit (nixpkgs) lib;

    # One nixosConfigurations output per host, named after its hostname and
    # defined in modules/hosts/<host>/. The shell picks one from NIX_HOST in
    # ~/.nix-host (see the dotfiles zsh setup).
    hosts = [
      "azepc-main"
      "azelap-x1g9"
      "azelap-p16g5"
      "azelap-ga502"
    ];

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          self.overlays.default
        ];
      };

    mkHost = hostName:
      lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          ./modules/hosts/${hostName}
          ./modules/system/system.nix
          home-manager.nixosModules.home-manager
          {
            networking.hostName = hostName;
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

    nixosConfigurations = lib.genAttrs hosts mkHost;

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
