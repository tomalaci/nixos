{
  pkgs,
  config,
  ...
}: {
  # NH nix helper cli config
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 14d";
    };
  };

  # System programs and utilities
  programs.zsh = {
    enable = true;
  };
  programs.mtr.enable = true;
  programs.ssh.startAgent = true;

  # Nix global library linking
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      curl
      dbus
      expat
      fontconfig
      freetype
      fuse3
      glib
      gtk3
      icu
      libdrm
      libglvnd
      libnotify
      libpulseaudio
      libxkbcommon
      mesa
      nspr
      nss
      openssl
      pango
      pipewire
      stdenv.cc.cc
      systemd
      vulkan-loader
      libx11
      libxscrnsaver
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrandr
      libxrender
      libxtst
      libxcb
      libxshmfence
      zlib
      config.boot.kernelPackages.nvidia_x11
    ];
  };

  environment.systemPackages = with pkgs; [
    # Nix tooling
    home-manager
    sops

    # Base development packages
    git
    gnumake
    bubblewrap
    nodejs_26
    python3
    go
    rustc
    binutils

    # CLI browsing, search, i/o parsing utilities
    bat
    doggo
    dua
    eza
    fd
    file
    fzf
    jq
    ripgrep
    yq

    # Network/Web utilities
    curl
    whois
    bind
    nmap
    traceroute
    trippy
    wget
    yt-dlp
    httpie

    # Hardware utilities
    gparted-full
    pciutils
    pcsc-tools
    usbutils
    yubikey-manager
    openrgb
    rivalcfg

    # Archives and installers
    gzip
    p7zip
    unrar

    # Cloud services
    gh
    awscli2
    hcloud
    cloudflared
    gdrive
    terraform
    kubectl
    k9s
    megasync
    megacmd
  ];
}
