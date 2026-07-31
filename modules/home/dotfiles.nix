# Out-of-store links to mutable application configuration in the dotfiles repo.
{config, ...}: let
  dotfilesDir = "${config.home.homeDirectory}/src/dotfiles/home";
  dotfile = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in {
  home.file = {
    ".config/Code/User/settings.json".source = dotfile "config/vscode/settings.json";
    ".config/zsh".source = dotfile "zsh";
    ".config/starship.toml".source = dotfile "config/starship.toml";
    ".codex/config.toml".source = dotfile "config/codex/config.toml";
    ".codex/rules/default.rules".source = dotfile "config/codex/rules/default.rules";
    ".config/mpv".source = dotfile "config/mpv";
    ".config/codebook".source = dotfile "config/codebook";
    ".config/plasma-localerc".source = dotfile "config/plasma/plasma-localerc";
    ".zshenv".source = dotfile "zsh/.zshenv";
    ".local/bin/context7-mcp".source = dotfile "local/bin/context7-mcp";
    ".local/bin/kde-fix-pinned-apps".source = dotfile "local/bin/kde-fix-pinned-apps";
  };
}
