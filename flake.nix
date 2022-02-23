{
  inputs = {
    faasd.url = "github:welteki/faasd-nix";
    nixos-shell.url = "github:Mic92/nixos-shell";
  };

  outputs = { self, nixpkgs, ... }@inputs: 
  let
    lib = nixpkgs.lib;

    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    version = "dev${builtins.substring 0 8 (self.lastModifiedDate)}-${self.shortRev or "dirty"}";
    commit = "${self.rev or "dirty"}";


    nixos-shell = inputs.nixos-shell.defaultPackage.${system};

    faasd = inputs.faasd.defaultPackage.${system}.overrideAttrs (old: rec {
      inherit version;

      src = ./.;

      ldflags = old.ldflags ++ [
        "-X main.Version=${version}"
        "-X main.GitCommit=${commit}"
      ];
    });
  in
  {
    nixosConfigurations.faasd-vm = lib.makeOverridable lib.nixosSystem {
      inherit system;
      modules = [
        inputs.faasd.nixosModules.faasd
        inputs.nixos-shell.nixosModules.nixos-shell

        ({ pkgs, ... }: {
          virtualisation.memorySize = 1024;
          nixos-shell.mounts.mountHome = false;

          services.faasd = {
            enable = true;
            package = faasd;
            basicAuth.enable = false;
          };
        })
      ];
    };

    defaultPackage.${system} = faasd;

    devShell.${system} = pkgs.mkShell {
      buildInputs = [ nixos-shell pkgs.faas-cli ];
    };
  };
}
