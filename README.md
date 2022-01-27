# dotfiles

My dotfiles.

This is all managed via [home-manager] and the [home.nix] configuration. `home.nix` will checkout this repository and link all the files to their correct places.

## Setup

You need to bootstrap `home-manager` so that it can do the rest. This only needs to be done once, after that see the [update](#update) instructions.

### Automatic Setup

The recommended way to run this is via [bootstrap].

### Manual Setup

Run `home-manager` with the `home.nix` configuration.

For example:

```sh
home_nix="$(mktemp -t home.nix)"
curl -L -o "${home_nix}" 'https://raw.githubusercontent.com/steinybot/dotfiles/main/.config/nixpkgs/home.nix'
home-manager -f "${home_nix}" switch
```

## Update

To pull in updates from this repository run:

```sh
home-manager switch
```

That will build and activate your current version of the configuration which may in turn update the configuration.

If the configuration has been updated then you will need to activate the new configuration:

```sh
home-manager switch
```

[bootstrap]: https://github.com/steinybot/bootstrap
[home.nix]: .config/nixpkgs/home.nix
[home manager]: https://github.com/nix-community/home-manager
