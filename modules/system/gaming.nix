{pkgs, ...}: {
  # Critical for Steam/Proton/Wine, especially older 32-bit games.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Gamescope is a micro-compositor that can be used to run games in a more isolated environment, with better performance and compatibility.
  programs.gamescope = {
    enable = true;
    enableWsi = true;
    capSysNice = false;
  };

  # Steam has system-level integration bits, so prefer NixOS module.
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;

    # Optional but useful for running random stuff through Steam runtime.
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
    extraPackages = with pkgs; [
      steam-run
      libgudev
    ];
  };

  # Installs + enables system service integration.
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    # Wine / Proton management
    wineWow64Packages.stableFull
    winetricks
    protonup-qt
    bottles
    lutris
    umu-launcher

    # Graphics / debugging utilities
    vulkan-tools # vulkaninfo
    mesa-demos # glxgears etc., also includes/replaces glxinfo
    mangohud
  ];
}
