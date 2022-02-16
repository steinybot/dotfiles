alias nix-bootstrap="nix-shell -p git --run 'nix-shell https://github.com/steinybot/bootstrap/archive/main.tar.gz --option tarball-ttl 0 --run exit'"
alias home-update="home-manager switch --option tarball-ttl 0"

# Set NIX_PATH explicitly to work around https://github.com/NixOS/nixpkgs/issues/149791.
# The path is the same as the default when NIX_PATH is not set (https://github.com/NixOS/nix/blob/master/src/libexpr/eval.cc).
# TODO: Put exports somewhere else.
NIX_STATE_DIR="/nix/var/nix"
export NIX_PATH="${NIX_PATH:-${HOME}/.nix-defexpr/channels:nixpkgs=${NIX_STATE_DIR}/profiles/per-user/root/channels/nixpkgs:${NIX_STATE_DIR}/profiles/per-user/root/channels}"
