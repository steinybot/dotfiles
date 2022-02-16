{ config, pkgs, ... }:

let
  # The path to this repository once it has been checked out.
  dotFilesRepo = fetchGit {
    url = "https://github.com/steinybot/dotfiles.git";
    ref = "main";
  };
  homeFilesDirectory = "${dotFilesRepo}/home";

  # Add these manually so that we can specify custom onChange etc.
  managedHomeFiles = {
    # This may update itself so we might need to run again.
    ".config/nixpkgs/home.nix" = {
      source = "${homeFilesDirectory}/.config/nixpkgs/home.nix";
      onChange = "home-manager --option tarball-ttl 0 switch";
    };

    # Run rebuild when the configuration changes.
    ".nixpkgs/darwin-configuration.nix" = {
      source = "${homeFilesDirectory}/.nixpkgs/darwin-configuration.nix";
      onChange = "darwin-rebuild switch";
    };

    # Update the channels when they change.
    # FIXME: This onChange needs to run first.
    ".nix-channels" = {
      source = "${homeFilesDirectory}/.nix-channels";
      onChange = "nix-channel --update";
    };
  };
  managedHomeFileNames = builtins.attrNames managedHomeFiles;

  # Add all the rest of the files in home automatically.
  unmanagedHomeFileNames = builtins.removeAttrs (builtins.readDir homeFilesDirectory) managedHomeFileNames;
  unmanagedHomeFiles = builtins.mapAttrs (name: value: {
      source = "${homeFilesDirectory}/${name}";
      # This has to be recursive otherwise we get an error saying:
      # Error installing file '...' outside $HOME
      # When using something like programs.git which will try and write
      # to .config but if that directory is a symlink then it is outside
      # of $HOME.
      recursive = true;
    }) unmanagedHomeFileNames;

  packages = with pkgs; [
    # FIXME: Not supported on aarch64-darwin.
    # https://github.com/NixOS/nixpkgs/pull/160115
    #jetbrains.idea-ultimate
    sbt
    scala
    # FIXME: This doesn't work as glibc-2.33-59 is not supported on aarch64-darwin.
    #steam
  ];

  customPkgsRepo = fetchGit {
    url = "https://github.com/steinybot/nixpkgs.git";
    ref = "fix/jetbrains-apple";
  };
  customPkgs = import customPkgsRepo {};
  customPackages = with customPkgs; [
    jetbrains.idea-ultimate
  ];
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "jason";
  home.homeDirectory = "/Users/jason";

  # Link home files.
  home.file = managedHomeFiles // unmanagedHomeFiles;

  # Install packages.
  home.packages = packages ++ customPackages;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Keep git even if you do not use it so that fetchGit works even
  # if XCode is not installed.
  programs.git = {
    enable = true;
    delta = {
      enable = true;
    };
    includes = [
      {
        contents = {
          user.email = "jasonpickensnz@gmail.com";
        };
      }
      {
        condition = "gitdir:~/src/goodcover/";
        contents = {
          user.email = "jason@goodcover.com";
        };
      }
    ];
    signing = {
      key = "C4A8C75C7876F1B5";
      signByDefault = true;
    };
    userName = "Jason Pickens";
  };
}
