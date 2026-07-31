{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

    mkDevShells = pkgs: let
      nixPackages = with pkgs; [
        alejandra
        deadnix
        nix-output-monitor
        nix-tree
        nixd
        nvd
        statix
      ];

      goPackages = with pkgs; [
        delve
        go
        go-tools
        golangci-lint
        gopls
      ];

      k8sHelm = pkgs.wrapHelm pkgs.kubernetes-helm {
        plugins = with pkgs.kubernetes-helmPlugins; [
          helm-diff
          helm-secrets
        ];
      };

      k8sPackages = with pkgs; [
        k8sHelm
        k9s
        kind
        kubectl
        kubectx
        minikube
        stern
      ];

      python = pkgs.python3.withPackages (python-pkgs:
        with python-pkgs; [
          ipython
          pip
          virtualenv
        ]);

      pythonPackages = with pkgs; [
        basedpyright
        python
        ruff
        uv
      ];

      rustPackages = with pkgs; [
        cargo
        cargo-edit
        cargo-nextest
        cargo-watch
        clippy
        rust-analyzer
        rust-bindgen
        rustc
        rustfmt
      ];

      typstPackages = with pkgs; [
        tinymist
        typstyle
        typst
      ];

      webPackages = with pkgs; [
        eslint
        nodejs_26
        pnpm
        prettier
        typescript
        typescript-language-server
        yarn
      ];

      mkShell = packages: pkgs.mkShell {inherit packages;};
    in {
      default = mkShell nixPackages;
      go = mkShell goPackages;
      k8s = mkShell k8sPackages;
      python = mkShell pythonPackages;
      rust = mkShell rustPackages;
      typst = mkShell typstPackages;
      web = mkShell webPackages;
      full = mkShell (
        nixPackages
        ++ goPackages
        ++ k8sPackages
        ++ pythonPackages
        ++ rustPackages
        ++ typstPackages
        ++ webPackages
      );
    };
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

    devShells.${system} = mkDevShells pkgs;
  };
}
