{ config, pkgs, ... }:

let
  # The path to this repository once it has been checked out.
  dotFilesRepo = fetchGit {
    url = "https://github.com/steinybot/dotfiles.git";
    ref = "main";
  };

  # Link everything in home.
  homeFilesDirectory = "${dotFilesRepo}/home";
  homeFileNames = builtins.readDir homeFilesDirectory;
  homeFiles = builtins.mapAttrs (name: value: {
      source = "${homeFilesDirectory}/${name}";
      # Since this may update itself we might need to run again.
      # TODO: Is there anyway to do this only if home.nix changes?
      ${ if name == ".config" then "onChange" else null } = "home-manager switch";
    }) homeFileNames;
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "jason";
  home.homeDirectory = "/Users/jason";

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

  # Link everything.
  home.file = homeFiles;
}