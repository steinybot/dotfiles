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
    # FIXME: This is not true.
    # GUI applications have to be installed with Nix Darwin and not Home Manager otherwise they
    # do not work with Spotlight etc. See https://github.com/nix-community/home-manager/issues/1341.
    iterm2
    jetbrains.idea-ultimate
    customIntelPkgs.keybase-gui
    mas
  ];
in
{
  environment = {
    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    systemPackages = packages ++ customPackages;

    #variables = {
    #  # Set NIX_PATH explicitly to work around https://github.com/NixOS/nixpkgs/issues/149791.
    #  # The path is the same as the default when NIX_PATH is not set (https://github.com/NixOS/nix/blob/master/src/libexpr/eval.cc).
    #  NIX_PATH = "\${NIX_PATH:-\${HOME}/.nix-defexpr/channels:nixpkgs=${nixStateDir}/profiles/per-user/root/channels/nixpkgs:${nixStateDir}/profiles/per-user/root/channels}";
    #};
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

    keyboard.remapCapsLockToEscape = true;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 4;
  };

  time.timeZone = "Pacific/Auckland";

  users.users.jason = {
    createHome = true;
    description = "Jason Pickens";
    home = "/Users/jason";
    name = "Jason Pickens";
    shell = pkgs.oh-my-zsh;
  };
}
