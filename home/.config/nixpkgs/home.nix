args@{ config, pkgs, ... }:

let
  # The path to this repository once it has been checked out.
  dotFilesRepo = fetchGit {
    url = "https://github.com/steinybot/dotfiles.git";
    ref = "main";
  };

  # Link everything in home.
  homeFilesDirectory = "${dotFilesRepo}/home";
  homeFileNames = builtins.readDir homeFilesDirectory;
  wtf = builtins.trace config false;
  homeFiles = builtins.mapAttrs (name: value: {
      source = "${homeFilesDirectory}/${name}";
      # This has to be recursive otherwise we get an error saying:
      # Error installing file '...' outside $HOME
      # When using something like programs.git which will try and write
      # to .config but if that directory is a symlink then it is outside
      # of $HOME.
      recursive = true;
    }) homeFileNames;
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "jason";
  home.homeDirectory = "/Users/jason";

  # Link everything.
  home.file = homeFiles // {
    # Add this independently so that we can add an onChange just to this one
    # file since this may update itself we might need to run again.
    ".config/nixpkgs/home.nix" = {
      source = "${homeFilesDirectory}/.config/nixpkgs/home.nix";
      onChange = "home-manager --option tarball-ttl 0 --arg activateChanges false switch";
    };
  };

  # Install packages.
  home.packages = with pkgs; [
  ];

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