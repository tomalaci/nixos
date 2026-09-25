# Out-of-store links to mutable application configuration in the dotfiles repo.
{config, ...}: let
  dotfilesDir = "${config.home.homeDirectory}/src/dotfiles/home";
  dotfile = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in {
  home.file = {
    ".config/Code/User/settings.json".source = dotfile "config/vscode/settings.json";
    ".config/zsh".source = dotfile "zsh";
    ".config/starship.toml".source = dotfile "config/starship.toml";
    ".config/mpv".source = dotfile "config/mpv";
    ".config/plasma-localerc".source = dotfile "config/plasma/plasma-localerc";
    ".config/kde-pinned-apps.conf".source = dotfile "config/plasma/kde-pinned-apps.conf";
    ".config/autostart/kde-fix-pinned-apps.desktop".source = dotfile "config/plasma/kde-fix-pinned-apps.desktop";
    ".local/share/kio/servicemenus/flatten-folders.desktop".source = dotfile "config/dolphin/flatten-folders.desktop";
    ".zshenv".source = dotfile "zsh/.zshenv";
    ".local/bin/dolphin-flatten-folders".source = dotfile "local/bin/dolphin-flatten-folders";
    ".local/bin/kde-fix-pinned-apps".source = dotfile "local/bin/kde-fix-pinned-apps";
  };
}
