# dotfiles

My dotfiles.

This is all managed via **Nix Flakes**, **nix-darwin**, and **Home Manager**.

## Prerequisites

### XCode

You need to sign in to the App Store:

```shell
open -a "App Store"
```

Then install `Xcode` manually.

Lastly, agree to the Xcode license agreements:

```shell
sudo xcodebuild -license
```

### Rosetta 2

Some Nix packages are not built for Apple M1 yet and need to be emulated with Rosetta 2.

To install Rosetta 2:

```shell
sudo softwareupdate --install-rosetta --agree-to-license
```

If that fails, try:

```shell
open '/System/Library/CoreServices/Rosetta 2 Updater.app'
```

### Nix

Install Nix (multi-user installation recommended):

```shell
sh <(curl -L https://nixos.org/nix/install)
```

## Setup

1. Clone this repository:
   ```shell
   mkdir -p ~/src
   git clone https://github.com/steinybot/dotfiles.git ~/src/dotfiles
   cd ~/src/dotfiles
   ```

2. Build and Apply the configuration:
   ```shell
   nix build --extra-experimental-features "nix-command flakes" .#darwinConfigurations.goodness.system
   ./result/sw/bin/darwin-rebuild switch --flake .
   ```

## Update

To pull in updates from this repository and apply them:

```shell
cd ~/src/dotfiles
git pull
darwin-rebuild switch --flake .
```

### Aliases

- `home-update`: Rebuilds the system configuration from `~/src/dotfiles`.

This command runs: `darwin-rebuild switch --flake ~/src/dotfiles`

> **Note**: You will see a "Git tree is dirty" warning if you have uncommitted changes. This is normal and serves as a helpful reminder.

## Troubleshooting

### Build Failures

If the build fails, check the logs. Common issues include deprecated options or failing package builds.

You can inspect the build log by redirecting output:

```shell
nix build .#darwinConfigurations.goodness.system > build.log 2>&1
```

### Bootstrap

If you need to bootstrap from scratch, you can use the `nix-bootstrap` alias or run the bootstrap script manually (see `bootstrap.sh` in the repo history or `steinybot/bootstrap` repo).
