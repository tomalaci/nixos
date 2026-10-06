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
    vesktop
    upscayl
    kdePackages.kcalc
    kdePackages.kdialog
    # Browse and edit the KWallet keyring (also serves the Secret Service API).
    kdePackages.kwalletmanager
    libreoffice
    godot
    blender
  ];
}
