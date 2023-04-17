# dotfiles

My dotfiles.

This is all managed via [Home Manager] and the [home.nix] configuration. `home.nix` will checkout this repository and
link all the files to their correct places.

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

## Setup

You need to bootstrap `home-manager` so that it can do the rest. This only needs to be done once, after that see the
[update](#update) instructions.

### Automatic Setup

The recommended way to run this is via [bootstrap].

### Manual Setup

#### GitHub Personal Access Token

1. Create a GitHub [Personal Access Token (classic)] with the scope `repo`
2. Add the token to `~/.config/nix/secrets.conf`:
   ```
   access-tokens = github.com=<access_token>
   ```
3. Add the [Goodcover settings] to `~/.config/nix/secrets.conf`.

#### Run Home Manager

Run `home-manager` with the `home.nix` configuration.

For example:

```shell
home_nix="$(mktemp -t home.nix)"
curl -L -o "${home_nix}" 'https://raw.githubusercontent.com/steinybot/dotfiles/main/.config/nixpkgs/home.nix'
home-manager -f "${home_nix}" switch
```

## Update

To pull in updates from this repository run:

```shell
home-manager switch --option tarball-ttl 0
```

Or use the alias:

```shell
home-update
```

That will build and activate your current version of the configuration which may in turn update the configuration.

If `home/.config` changes then `home-manager` will be rerun to activate the new configuration.

## Troubleshooting

### Bad Configuration

The downside to having `home-manager` manage its own configuration is that if the configuration is invalid then it
cannot update itself.

To fix that you may need to run `bootstrap` again:

```shell
nix-bootstrap
```

Assuming that you have this repository checked out to `~/src/dotfiles`, you can make changes there and then run:

```shell
home-update-local
```

[bootstrap]: https://github.com/steinybot/bootstrap
[goodcover settings]: https://github.com/goodcover/gc-nix#add-settings-to-use-our-cache
[home.nix]: home/.config/nixpkgs/home.nix
[home manager]: https://github.com/nix-community/home-manager
[personal access token (classic)]: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#creating-a-personal-access-token-classic
