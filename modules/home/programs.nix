# Desktop applications and general-purpose utilities.
{pkgs, ...}: {
  home.packages = with pkgs; [
    btop
    fastfetch
    ffmpeg-full
    firefox
    gh
    htop
    jellyfin-media-player
    krita
    mpv
    qbittorrent
    slack
    vesktop
    upscayl
    yt-dlp
    megasync
  ];
}
