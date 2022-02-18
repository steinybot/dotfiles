{ config, pkgs, ... }:

let
  packages = with pkgs; [
    git
    tree
    vim
  ];

  customPkgsRepo = fetchGit {
    url = "https://github.com/steinybot/nixpkgs.git";
    ref = "dev";
  };
  customPkgs = import customPkgsRepo {};
  customIntelPkgs = import customPkgsRepo { system = "x86_64-darwin"; };
  customPackages = with customPkgs; [
    # GUI applications have to be installed with Nix Darwin and not Home Manager otherwise they
    # do not work with Spotlight etc. See https://github.com/nix-community/home-manager/issues/1341.
    iterm2
    jetbrains.idea-ultimate
    customIntelPkgs.keybase-gui
    mas
  ];
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = packages ++ customPackages;

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  nix.extraOptions = ''
    # With Rosetta 2 we can run Intell apps on Apple M1.
    extra-platforms = x86_64-darwin aarch64-darwin
  '';
}
