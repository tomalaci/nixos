# KDE Plasma desktop environment configuration for NixOS
{pkgs, ...}: {
  qt.enable = true;
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "plasma";
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];

    config.common = {
      default = ["kde"];
      "org.freedesktop.impl.portal.ScreenCast" = ["kde"];
      "org.freedesktop.impl.portal.Screenshot" = ["kde"];
    };
  };

  # KDE connect
  programs.kdeconnect.enable = true;
  networking.firewall = rec {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };
}
