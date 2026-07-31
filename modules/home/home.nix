{
  config,
  lib,
  ...
}: {
  # Global home-manager configuration
  programs.home-manager.enable = true;
  xdg.enable = true;

  # User home
  home = {
    username = "tomalaci";
    homeDirectory = "/home/tomalaci";
    stateVersion = "26.05";
  };

  # Login environment variables
  home.sessionVariables = {
    XDG_BIN_HOME = lib.mkDefault config.xdg.binHome;
    XDG_CACHE_HOME = lib.mkDefault config.xdg.cacheHome;
    XDG_CONFIG_HOME = lib.mkDefault config.xdg.configHome;
    XDG_DATA_HOME = lib.mkDefault config.xdg.dataHome;
    XDG_STATE_HOME = lib.mkDefault config.xdg.stateHome;
  };

  # Home submodules
  imports = [
    ./dotfiles.nix
    ./shell.nix
    ./programs.nix
    ./development.nix
  ];
}
