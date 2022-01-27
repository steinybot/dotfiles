# dotfiles

My dotfiles.

## Automatic Setup

The recommended way to run this is via [bootstrap].

## Manual Setup

Run `home-manager` with the [home.nix] configuration.

For example:

```sh
home_nix="$(mktemp -t home.nix)"
curl -L -o "${home_nix}" 'https://raw.githubusercontent.com/steinybot/dotfiles/main/.config/nixpkgs/home.nix'
home-manager -f "${home_nix}" switch
```

[bootstrap]: https://github.com/steinybot/bootstrap
[home.nix]: .config/nixpkgs/home.nix
