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

  # Git configuration
  programs.git = {
    enable = true;
    # Playwright MCP writes page snapshots and console logs to the working directory.
    ignores = [".playwright-mcp/" ".venv" "node_modules"];
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      user = {
        email = "tomass.lacis@pm.me";
        name = "Tomass Lacis";
      };
    };
  };

  # Login environment variables
  home.sessionVariables = {
    XDG_BIN_HOME = lib.mkDefault config.xdg.binHome;
    XDG_CACHE_HOME = lib.mkDefault config.xdg.cacheHome;
    XDG_CONFIG_HOME = lib.mkDefault config.xdg.configHome;
    XDG_DATA_HOME = lib.mkDefault config.xdg.dataHome;
    XDG_STATE_HOME = lib.mkDefault config.xdg.stateHome;
  };

  # Dotfiles scripts linked into ~/.local/bin; ai-config.nix adds its own bin/.
  home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];

  # Home submodules
  imports = [
    ./dotfiles.nix
    ./ai-config.nix
    ./shell.nix
    ./programs.nix
    ./scheduled-jobs.nix
  ];
}
