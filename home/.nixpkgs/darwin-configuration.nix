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
    # FIXME: This is not true.
    # GUI applications have to be installed with Nix Darwin and not Home Manager otherwise they
    # do not work with Spotlight etc. See https://github.com/nix-community/home-manager/issues/1341.
    #iterm2
  ];
in
{
  environment = {
    shells = with pkgs; [ bashInteractive zsh ];
  
    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    systemPackages = packages ++ customPackages;
  };

  # I give in...
  homebrew = {
    enable = true;

    brews = [
      "act"
      "awscli"
      "bun"
      "colima"
      "coursier"
      "coreutils"
      "gh"
      "git"
      "go@1.21"
      "gofumpt"
      "golangci-lint"
      "graphviz"
      "hyperfine"
      "jackett"
      "jenv"
      "jq"
      "mpv"
      "node"
      "nodenv"
      "nodenv/nodenv/nodenv-default-packages"
      "node-build"
      "pandoc"
      "pulumi"
      "pulumictl"
      "pyenv"
      "rustup"
      "safe-rm"
      "tfenv"
      "watchman"
      "xml-coreutils"
      "zabbix"
    ];
    casks = [
      "aws-vault"
      "beyond-compare"
      # This often times out trying to download.
      # You might need to download it manually and run:
      # brew --cache --build-from-source blender
      # to get the path to where it needs to go.
      # See https://docs.brew.sh/Tips-N'-Tricks#pre-download-a-file-for-a-formula
      "blender"
      "brave-browser"
      "discord"
      "disk-inventory-x"
      "docker"
      "dotnet-sdk"
      "epic-games"
      "firefox"
      "freecad"
      "gimp"
      "google-chrome"
      "intellij-idea"
      "iterm2"
      "jdk-mission-control"
      "keybase"
      "keepassx"
      "lastpass"
      "parallels"
      "postman"
      "protonvpn"
      "qbittorrent"
      "raycast"
      "roundpie"
      "slack"
      "steam"
      "todoist"
      "universal-media-server"
      "visual-studio-code"
      "visualvm"
      "vlc"
      "vuze"
      "webstorm"
      "whatsapp"
      "wireshark"
    ];
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
#    masApps = {
#      Xcode = 497799835;
#    };
    taps = [
      "homebrew/services"
      "nodenv/nodenv"
      "oven-sh/bun"
      "pulumi/tap"
    ];
  };

  networking = {
    computerName = "Goodness Gracious";
    hostName = "goodness";
  };

  nix = {
    extraOptions = ''
      # With Rosetta 2 we can run Intell apps on Apple M1.
      extra-platforms = x86_64-darwin

      experimental-features = nix-command flakes

      # Prevent nix-shell stuff from being garbage collected (for nix-direnv).
      keep-outputs = true
      keep-derivations = true
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
    # Create /etc/bashrc that loads the nix-darwin environment.
    bash = {
      enable = true;
    };

    # Don't use the gnupg agent that is provided here as it doesn't work properly. Set it up using home-manager instead.
    # See: https://discourse.nixos.org/t/how-to-make-gpg-use-the-agent-from-programs-gnupg-agent/11834

    # Create /etc/zshrc that loads the nix-darwin environment.
    zsh = {
      enable = true;
    };
  };

  services = {
    # Auto upgrade nix package and the daemon service.
    nix-daemon.enable = true;
  };

  system = {
    activationScripts = {
      postActivation.text = ''
        grep -q '\slocal\.goodcover\.com' /etc/hosts || cat << 'EOF' >> /etc/hosts

        # Host name for local Goodcover development.
        # Never use .local TLD (https://datatracker.ietf.org/doc/html/rfc6762).
        127.0.0.1       local.goodcover.com
        EOF
      '';
    };

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
    uid = 501;
    createHome = true;
    description = "Jason Pickens";
    home = "/Users/jason";
    name = "Jason Pickens";
    shell = pkgs.zsh;
  };
}
