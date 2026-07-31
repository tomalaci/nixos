{pkgs, ...}: {
  home.packages = with pkgs; [
    starship
    zsh-autosuggestions
    zsh-completions
    zsh-syntax-highlighting
  ];

  # Zsh startup files and Starship config are owned by the dotfiles repo via modules/home/dotfiles.nix.

  # Konsole terminal configuration
  xdg.configFile."konsolerc".text = ''
    [Desktop Entry]
    DefaultProfile=Tomalaci.profile

    [General]
    ConfigVersion=1
  '';

  xdg.dataFile."konsole/Tomalaci.profile".text = ''
    [Appearance]
    Font=MesloLGS Nerd Font Mono,10,-1,5,50,0,0,0,0,0

    [General]
    Name=Tomalaci
    Parent=FALLBACK/
  '';

  # zoxide is a smarter cd alternative, with support for fuzzy matching and directory frecency
  programs.zoxide = {
    enable = true;
    enableZshIntegration = false;
  };
}
