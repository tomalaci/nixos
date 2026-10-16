# Desktop applications and general-purpose utilities.
{pkgs, ...}: {
  # Visual Studio Code configuration
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = true;
  };

  # Other home packages
  home.packages = with pkgs; [
    firefox
    jellyfin-media-player
    krita
    qbittorrent
    slack
    anydesk # remote help on sandalap-ga502 (~/src/tomalaci/nixos-sanda)
    vesktop
    upscayl
    kdePackages.kcalc
    kdePackages.kdialog
    libreoffice
    godot
    blender
  ];
}
