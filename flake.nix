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
      # Pinned: d38b07d (2026-10-04) runs scripts/generate_plasmoid_i18n.py in
      # nix/package.nix but leaves it out of the source fileset, so the build
      # fails. Unpin (drop the revision) once upstream fixes it.
      url = "github:loteran/Arctis-Sound-Manager/bbb0fed06bbb379ef4af708337b3d959268bcffb?dir=nix";
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
      # Template for new hosts, never installed; evaluated to keep it working.
      "azehost-example"
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
          # Hosts declare their disks in modules/hosts/<host>/disko.nix; without
          # one (azepc-main) the module does nothing.
          inputs.disko.nixosModules.disko
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
