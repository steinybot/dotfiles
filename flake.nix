{
  description = "Jason's macOS Dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, darwin, home-manager, nixpkgs, ... }@inputs:
  let
    system = "aarch64-darwin"; # Assuming M1/Apple Silicon based on existing config mentioning Rosetta 2
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          bcompare = prev.bcompare.overrideAttrs (old: {
            postInstall =
              ''
                ${(old.postInstall or "")}

                ln $out/Applications/BCompare.app/Contents/MacOS/bcomp bin/bcomp
              '';
          });
        })
      ];
    };
  in
  {
    darwinConfigurations."goodness" = darwin.lib.darwinSystem {
      inherit system;
      modules = [
        ./home/.nixpkgs/darwin-configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.jason = import ./home/.config/home-manager/home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
      specialArgs = { inherit inputs; };
    };
  };
}
