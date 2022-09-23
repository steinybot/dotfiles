{ config, pkgs, ... }:

let
  username = "jason";
  homeDirectory = "/Users/${username}";

  patchesDirectory = ../../../patches;

  srcDirectory = "${homeDirectory}/src";
  dotfilesSrcDirectory = "${srcDirectory}/dotfiles";
  goodcoverSrcDirectory = "${srcDirectory}/goodcover";
  goodcoverCoreDirectory = "${goodcoverSrcDirectory}/core";

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
        pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
        default-cache-ttl 600
        max-cache-ttl 7200
        default-cache-ttl-ssh 600
        max-cache-ttl-ssh 7200
        log-file ${homeDirectory}/.gnupg/gpg-agent.log
      '';
    };

    "Library/Java/JavaVirtualMachines/graalvm11-ce" = {
      source = toString intelPkgs.graalvm11-ce;
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

  # Prefer using pkgsCross but some packages do not cross build so we have to build the whole thing for x86_64.
  # TODO: Where should <nixpkgs> come from?
  intelPkgs = import <nixpkgs> {
    system = "x86_64-darwin";
  };

  unstablePkgsRepo = fetchGit {
    url = "https://github.com/nixos/nixpkgs.git";
    ref = "nixpkgs-unstable";
  };
  unstablePkgs = import unstablePkgsRepo {
    overlays = [
        (self: super: {
          bcompare = super.bcompare.overrideAttrs (old: {
            postInstall =
              ''
                ${(old.postInstall or "")}

                ln $out/Applications/BCompare.app/Contents/MacOS/bcomp bin/bcomp
              '';
          });
        })
      ];
  };

#  customPkgsRepo = fetchGit {
#    url = "https://github.com/steinybot/nixpkgs.git";
#    ref = "dev";
#  };
#  customPkgs = import customPkgsRepo {};

  shellAliases = {
    nix-bootstrap = "sh <(curl -L https://raw.githubusercontent.com/steinybot/bootstrap/main/bootstrap.sh)";
    home-update = "home-manager --option tarball-ttl 0 switch";
    home-update-local = "home-manager -f '${dotfilesSrcDirectory}/home/.config/nixpkgs/home.nix' --option tarball-ttl 0 switch";
  };
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
    packages = with pkgs; [
      ammonite
      unstablePkgs.bcompare
      cassandra
      element-desktop
      gnupg
      intelPkgs.graalvm11-ce
      jq
      maven
      mysql
      pinentry_mac
      unstablePkgs.postman
      ripgrep
      sbt
      scala
      surfraw # This needs a browser such as w3m.
      thefuck
      w3m
      yarn
    ];

    sessionPath = [
      # Add Keybase to the PATH.
      #"${customPkgs.pkgsCross.x86_64-darwin.keybase-gui}/Applications/Keybase.app/Contents/SharedSupport/bin"
      "${homeDirectory}/Library/Application Support/Coursier/bin"
    ];

    sessionVariables = {
      EDITOR = "vim";
      LPASS_PINENTRY = "${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac";
      # I don't know why we need this. Nix-darwin is supposed to manage the agent for us.
      # See https://discourse.nixos.org/t/how-to-make-gpg-use-the-agent-from-programs-gnupg-agent/11834.
      SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
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

  launchd.agents = {
    gcCassandra = {
      enable = true;
      config = {
        EnvironmentVariables = {
          MAX_HEAP_SIZE = "4G";
          HEAP_NEWSIZE = "800M";
          CASSANDRA_LOG_DIR = "${goodcoverCoreDirectory}/datadir/cassandra/logs";
        };
        Label = "com.goodcover.cassandra";
        ProgramArguments = [
          "${pkgs.cassandra}/bin/cassandra"
          "-f"
          "-Dcassandra.config=file://${homeDirectory}/.config/goodcover/cassandra.yaml"
        ];
      };
    };
    gcMySQL = {
      enable = true;
      config = {
        Label = "com.goodcover.mysql";
        ProgramArguments = [
          "${pkgs.mysql}/bin/mysqld_safe"
          "--datadir=${goodcoverCoreDirectory}/datadir/mysql"
          "--log-error=${goodcoverCoreDirectory}/datadir/mysql/mysql.err"
          "--socket=${goodcoverCoreDirectory}/datadir/mysql.sock"
        ];
      };
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      bcompare = super.bcompare.overrideAttrs (old: {
        postInstall =
          ''
            ${(old.postInstall or "")}

            ln $out/Applications/BCompare.app/Contents/MacOS/bcomp bin/bcomp
          '';
      });
      cassandra = super.cassandra.overrideAttrs (old: {
        # Workaround for https://github.com/NixOS/nixpkgs/issues/165175.
        patches = (old.patches or []) ++
          builtins.map
            (name: "${patchesDirectory}/cassandra/${name}")
            (builtins.attrNames (builtins.readDir "${patchesDirectory}/cassandra"));
        postInstall =
          let
            jna = pkgs.fetchurl {
              url = "https://repo1.maven.org/maven2/net/java/dev/jna/jna/5.10.0/jna-5.10.0.jar";
              sha256 = "sha256-4zXBBnn3QyB9gixfeUjpMDGYNUkldanbprlPijuW/Mg=";
            };
          in ''
            ${(old.postInstall or "")}

            rm "$out/lib/jna-4.2.2.jar"
            cp "${jna}" "$out/lib/"
          '';
      });
    })
  ];

  programs = {
    bash = {
      enable = true;
      initExtra = ''
        source ~/.config/iterm2/.iterm2_shell_integration.bash
      '';
      profileExtra = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"

        eval "$(nodenv init -)"
      '';
      shellAliases = shellAliases;
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv = {
        enable = true;
      };
    };

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
          # This needs git 2.37
          #autoSetupMerge = "simple";
          autoSetupMerge = false;
        };
        core = {
          autocrlf = false;
        };
        diff = {
          tool = "bcomp";
        };
        difftool = {
          prompt = false;
          "bcomp" = {
            cmd = ''bcomp "$LOCAL" "$REMOTE"'';
            trustExitCode = true;
          };
        };
        init = {
          defaultBranch = "main";
        };
        merge = {
          ff = false;
          tool = "bcomp";
        };
        mergetool = {
          keepBackup = false;
          prompt = false;
          "bcomp" = {
            cmd = ''bcomp "$LOCAL" "$REMOTE" "$BASE" "$MERGED"'';
            trustExitCode = true;
          };
        };
        pull = {
          ff = "only";
        };
        push = {
          autoSetupRemote = true;
          default = "simple";
        };
        url = {
          "ssh://git@github.com" = {
            insteadOf = "https://github.com";
          };
        };
      };
      includes = [
        {
          condition = "gitdir:${goodcoverSrcDirectory}";
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
      initExtra = ''
        source ~/.config/iterm2/.iterm2_shell_integration.zsh
      '';
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "thefuck" ];
      };
      profileExtra = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"

        eval "$(nodenv init -)"
      '';
      shellAliases = shellAliases;
    };
  };
}
