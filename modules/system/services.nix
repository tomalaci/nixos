{pkgs, ...}: {
  # Network management
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Tailscale
  services.tailscale.enable = true;

  # Virtualization
  # Note: "virtualisation" is the correct config option (spelled after the British English convention)
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Usenet services.
  services.nzbget = {
    enable = true;
    user = "tomalaci";
    group = "users";
  };
  services.nzbhydra2.enable = true;

  # Smartcard access for YubiKeys.
  services.pcscd.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Peripheral services
  services.hardware.openrgb.enable = true;
  services.udev.packages = [pkgs.rivalcfg];
  services.arctis-sound-manager.enable = true;
  services.input-remapper = {
    enable = true;
    enableUdevRules = true;
  };
}
