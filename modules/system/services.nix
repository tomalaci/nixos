{...}: {
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
  # Syncthing (modules/home/syncthing.nix) between machines, on the tailnet only.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22000];

  # Virtualization
  # Note: "virtualisation" is the correct config option (spelled after the British English convention)
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";

  # Enable CUPS to print documents.
  services.printing.enable = true;

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

  # Bluetooth on every host (Plasma manages pairing).
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = false;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };
}
