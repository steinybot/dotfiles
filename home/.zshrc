alias nix-bootstrap="nix-shell -p git --run 'nix-shell https://github.com/steinybot/bootstrap/archive/main.tar.gz --option tarball-ttl 0 --run exit'"
alias home-update="home-manager switch --option tarball-ttl 0"
