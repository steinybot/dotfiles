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
  customPackages = with customPkgs; [
    # GUI applications have to be installed with Nix Darwin and not Home Manager otherwise they
    # do not work with certain things like 'open'. They still do not work properly with Spotlight.
    # See https://github.com/nix-community/home-manager/issues/1341.
    iterm2
    jetbrains.idea-ultimate
    mas
    slack
  ];
  customIntelPkgs = import customPkgsRepo { system = "x86_64-darwin"; };
  customIntelPackages = with customIntelPkgs; [
    keybase-gui
  ];
in
{
  environment = {
    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    systemPackages = packages ++ customPackages ++ customIntelPackages;
  };

  networking = {
    computerName = "Goodness Gracious";
    hostName = "goodness";
  };

  nix = {
    extraOptions = ''
      # With Rosetta 2 we can run Intell apps on Apple M1.
      extra-platforms = x86_64-darwin aarch64-darwin
    '';

    nixPath = [
      {
        darwin-config = "\${HOME}/.nixpkgs/darwin-configuration.nix";
        nixpkgs = "/nix/var/nix/profiles/per-user/root/channels/nixpkgs";
      }
      "/nix/var/nix/profiles/per-user/root/channels"
      # FIXME: This ends up being there twice.
      "\${HOME}/.nix-defexpr/channels"
    ];

    package = pkgs.nix;
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    zsh = {
      enable = true;
      enableSyntaxHighlighting = true;
    };
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  system = {
    defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        ApplePressAndHoldEnabled = true;
        AppleShowAllExtensions = true;
      };

      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

      dock = {
        mru-spaces = false;
        show-recents = false;
      };

      finder = {
        FXEnableExtensionChangeWarning = false;
        QuitMenuItem = true;
        _FXShowPosixPathInTitle = true;
      };

      loginwindow = {
        GuestEnabled = false;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 4;
  };

  # FIXME: This doesn't work.
  #time.timeZone = "Pacific/Auckland";

  users.users.jason = {
    createHome = true;
    description = "Jason Pickens";
    home = "/Users/jason";
    name = "Jason Pickens";
    shell = pkgs.oh-my-zsh;
  };
}
