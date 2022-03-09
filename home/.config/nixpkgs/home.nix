{ config, pkgs, ... }:

let
  username = "jason";
  homeDirectory = "/Users/${username}";
  
  # The path to this repository once it has been checked out.
  dotFilesRepo = fetchGit {
    url = "https://github.com/steinybot/dotfiles.git";
    ref = "main";
  };
  repoHomeFilesDirectory = "${dotFilesRepo}/home";

  # Add these manually so that we can specify custom onChange etc.
  managedHomeFiles = {
    # This may update itself so we might need to run again.
    ".config/nixpkgs/home.nix" = {
      source = "${repoHomeFilesDirectory}/.config/nixpkgs/home.nix";
      onChange = "home-manager --option tarball-ttl 0 -b backup switch";
    };

    # Run rebuild when the configuration changes.
    ".nixpkgs/darwin-configuration.nix" = {
      source = "${repoHomeFilesDirectory}/.nixpkgs/darwin-configuration.nix";
      onChange = "darwin-rebuild switch";
    };

    # Update the channels when they change.
    # FIXME: This onChange needs to run first.
    ".nix-channels" = {
      source = "${repoHomeFilesDirectory}/.nix-channels";
      onChange = "nix-channel --update";
    };
    
    ".gnupg/gpg-agent.conf" = {
      text = ''
        enable-ssh-support
        pinentry-program ${homeDirectory}/.nix-profile/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
        default-cache-ttl 600
        max-cache-ttl 7200
        default-cache-ttl-ssh 600
        max-cache-ttl-ssh 7200
      '';
    };
  };
  managedHomeFileNames = builtins.attrNames managedHomeFiles;

  # Add all the rest of the files in home automatically.
  unmanagedHomeFileNames = builtins.removeAttrs (builtins.readDir repoHomeFilesDirectory) managedHomeFileNames;
  unmanagedHomeFiles = builtins.mapAttrs (name: value: {
      source = "${repoHomeFilesDirectory}/${name}";
      # This has to be recursive otherwise we get an error saying:
      # Error installing file '...' outside $HOME
      # When using something like programs.git which will try and write
      # to .config but if that directory is a symlink then it is outside
      # of $HOME.
      recursive = true;
    }) unmanagedHomeFileNames;

  packages = with pkgs; [
    gnupg
    pinentry_mac
    sbt
    scala
    # FIXME: This doesn't work as glibc-2.33-59 is not supported on aarch64-darwin.
    #steam
    surfraw # This needs a browser such as w3m.
    thefuck
    w3m
  ];

  customPkgsRepo = fetchGit {
    url = "https://github.com/steinybot/nixpkgs.git";
    ref = "dev";
  };
  customPkgs = import customPkgsRepo {};
  customPackages = with customPkgs; [
    jetbrains.idea-ultimate
    slack
    pkgsCross.x86_64-darwin.keybase-gui
  ];
in
{
  home = {
    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    username = username;
    homeDirectory = homeDirectory;

    # Link home files.
    file = managedHomeFiles // unmanagedHomeFiles;

    # Install packages.
    packages = packages ++ customPackages;

    sessionVariables = {
      EDITOR = "vim";
    };

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "22.05";
  };

  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    # Keep git even if you do not use it so that fetchGit works even
    # if XCode is not installed.
    git = {
      enable = true;
      delta = {
        enable = true;
      };
      signing = {
        key = "C4A8C75C7876F1B5";
        signByDefault = true;
      };
      userName = "Jason Pickens";
      userEmail = "jasonpickensnz@gmail.com";
      extraConfig = {
        branch = {
          autoSetupMerge = false;
        };
        core = {
          autocrlf = false;
        };
        difftool = {
          prompt = false;
        };
        merge = {
          ff = false;
        };
        mergetool = {
          prompt = false;
        };
        pull = {
          ff = "only";
        };
        url = {
          "ssh://git@github.com" = {
            insteadOf = "https://github.com";
          };
        };
      };
      includes = [
        {
          condition = "gitdir:~/src/goodcover/";
          contents = {
            user.email = "jason@goodcover.com";
          };
        }
      ];
    };

    ssh = {
      enable = true;
      extraOptionOverrides = {
        IgnoreUnknown = "UseKeychain";
        UseKeychain = "yes";
      };
    };

    zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "thefuck" ];
      };
      shellAliases = {
        nix-bootstrap = "sh <(curl -L https://raw.githubusercontent.com/steinybot/bootstrap/main/bootstrap.sh)";
        home-update = "home-manager switch --option tarball-ttl 0";
      };
    };
  };
}
