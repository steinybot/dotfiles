{ config, pkgs, inputs, ... }:

let
  username = "jason";
  homeDirectory = "/Users/${username}";

  patchesDirectory = ../../../patches;

  srcDirectory = "${homeDirectory}/src";
  dotfilesSrcDirectory = "${srcDirectory}/dotfiles";

  # The path to this repository once it has been checked out.
  dotFilesRepo = inputs.self;
  # Use this if git/ssh is broken (such as when the PGP key expires).
  #dotFilesRepo = ../../..;
  repoHomeFilesDirectory = "${dotFilesRepo}/home";

  # Add these manually so that we can specify custom onChange etc.
  managedHomeFiles = {
    # This may update itself so we might need to run again.
    ".config/home-manager/home.nix" = {
      source = "${repoHomeFilesDirectory}/.config/home-manager/home.nix";

    };

    # Run rebuild when the configuration changes.
    ".nixpkgs/darwin-configuration.nix" = {
      source = "${repoHomeFilesDirectory}/.nixpkgs/darwin-configuration.nix";

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

#    "Library/Java/JavaVirtualMachines/graalvm11-ce" = {
#      source = toString intelPkgs.graalvm11-ce;
#    };
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
  # intelPkgs = import <nixpkgs> {
  #   system = "x86_64-darwin";
  # };

  shellAliases = {
    nix-bootstrap = "sh <(curl -L https://raw.githubusercontent.com/steinybot/bootstrap/main/bootstrap.sh)";
    home-update = "darwin-rebuild switch --flake ${dotfilesSrcDirectory}";

    rm = "safe-rm";
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
      element-desktop
      gnupg
      graalvmPackages.graalvm-ce
      jq
      maven
      pinentry_mac
      ripgrep
      surfraw # This needs a browser such as w3m.
      pay-respects
      w3m
      yarn
    ];

    sessionPath = [
      # Add Keybase to the PATH.
      #"${customPkgs.pkgsCross.x86_64-darwin.keybase-gui}/Applications/Keybase.app/Contents/SharedSupport/bin"
      "${homeDirectory}/Library/Application Support/Coursier/bin"
      "${homeDirectory}/bin"
      "${homeDirectory}/.cargo/bin"
      "/Applications/IntelliJ IDEA CE.app/Contents/MacOS"
    ];

    sessionVariables = {
      CONDA_EXE = "/opt/homebrew/Caskroom/miniforge/base/bin/conda";
      EDITOR = "vim";
      LPASS_PINENTRY = "${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac";
      # I don't know why we need this. Nix-darwin is supposed to manage the agent for us.
      # See https://discourse.nixos.org/t/how-to-make-gpg-use-the-agent-from-programs-gnupg-agent/11834.
      SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
      VI_MODE_SET_CURSOR = "true";
      VI_MODE_CURSOR_NORMAL = 4;
      VI_MODE_CURSOR_VISUAL = 2;
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
  };

  #nixpkgs.overlays = [
  #  # Overlays are now managed in flake.nix
  #];

  programs = {
    delta = {
      enable = true;
    };

    bash = {
      enable = true;
      # These go in ~/.bashrc.
      initExtra = ''
        source ~/.config/iterm2/.iterm2_shell_integration.bash

        # >>> mamba initialize >>>
        if [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/mamba.sh" ]; then
            . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/mamba.sh"
        fi
        # <<< mamba initialize <<<

        #THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
        export SDKMAN_DIR="$HOME/.sdkman"
        [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
      '';
      # These go in ~/.profile.
      profileExtra = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"

        eval "$(jenv init -)"

        eval "$(nodenv init -)"

        export PYENV_ROOT="$HOME/.pyenv"
        command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
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

      #signing = {
      #  key = "C4A8C75C7876F1B5";
      #  signByDefault = true;
      #};
      #userName = "Jason Pickens";
      #userEmail = "jasonpickensnz@gmail.com";
      settings = {
        user = {
          name = "Jason Pickens";
          email = "jasonpickensnz@gmail.com";
          signingKey = "C4A8C75C7876F1B5";
        };
        commit = {
          gpgSign = true;
        };
        branch = {
          autoSetupMerge = "simple";
        };
        core = {
          autocrlf = false;
          excludesfile = "~/.config/git/.gitignore";
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
      #includes = [
      #  {
      #    condition = "gitdir:${goodcoverSrcDirectory}";
      #    contents = {
      #      user.email = "jason@goodcover.com";
      #    };
      #  }
      #];
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks."*" = {
        extraOptions = {
          IgnoreUnknown = "UseKeychain";
          UseKeychain = "yes";
        };
        # This will start the gpg agent when using SSH.
        match = "host * exec \"gpg-connect-agent UPDATESTARTUPTTY /bye\"";
      };
    };

    zsh = {
      enable = true;
      # These go in ~/.zshrc.
      initContent = ''
        source ~/.config/iterm2/.iterm2_shell_integration.zsh

        # >>> conda initialize >>>
        # !! Contents within this block are managed by 'conda init' !!
        __conda_setup="$('/opt/homebrew/Caskroom/miniforge/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
        if [ $? -eq 0 ]; then
            eval "$__conda_setup"
        else
            if [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
                . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"
            else
                export PATH="/opt/homebrew/Caskroom/miniforge/base/bin:$PATH"
            fi
        fi
        unset __conda_setup
        # <<< conda initialize <<<

        # >>> mamba initialize >>>
        if [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/mamba.sh" ]; then
            . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/mamba.sh"
        fi
        # <<< mamba initialize <<<

        #THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
        export SDKMAN_DIR="$HOME/.sdkman"
        [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
      '';
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "vi-mode" ];
        theme = "dst";
      };
      # These go in ~/.zprofile.
      profileExtra = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"

        eval "$(jenv init -)"

        eval "$(nodenv init -)"

        export PYENV_ROOT="$HOME/.pyenv"
        command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
      '';
      shellAliases = shellAliases;
    };
  };
}
