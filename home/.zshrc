alias nix-bootstrap="sh <(curl -L https://raw.githubusercontent.com/steinybot/bootstrap/main/bootstrap.sh)"
alias home-update="home-manager switch --option tarball-ttl 0"

# TODO: Put exports somewhere else.

# Set NIX_PATH explicitly to work around https://github.com/NixOS/nixpkgs/issues/149791.
# The path is the same as the default when NIX_PATH is not set (https://github.com/NixOS/nix/blob/master/src/libexpr/eval.cc).
NIX_STATE_DIR="/nix/var/nix"
export NIX_PATH="${NIX_PATH:-${HOME}/.nix-defexpr/channels:nixpkgs=${NIX_STATE_DIR}/profiles/per-user/root/channels/nixpkgs:${NIX_STATE_DIR}/profiles/per-user/root/channels}"

export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
