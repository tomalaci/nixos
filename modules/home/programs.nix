# Desktop applications and general-purpose utilities.
{pkgs, ...}: {
  home.packages = with pkgs; [
    btop
    fastfetch
    ffmpeg-full
    firefox
    htop
    jellyfin-media-player
    krita
    inkscape
    mpv
    qbittorrent
    slack
    vesktop
    upscayl
    kdePackages.kcalc
    kdePackages.kdialog
    libreoffice
  ];
}
