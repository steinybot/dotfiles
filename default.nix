# {
#   imports = [];

#   options = {

#   };

#   config = {
#     home.file.".hello".source = "${fetchGit {
#       url = "git@github.com:steinybot/dotfiles.git";
#       ref = "main";
#     }}/.hello";
#   };
# }

{
  install = {
    shellHook =
      ''
        echo hello
      '';
  };
}