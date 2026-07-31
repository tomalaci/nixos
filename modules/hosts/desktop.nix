{
  config,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # === GENERAL ===
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "azepc-main";

  # === BOOT ===
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.extraModulePackages = [];
  boot.kernelModules = ["kvm-amd" "nvidia"];
  boot.kernelParams = ["nvidia_drm.modeset=1"];
  boot.blacklistedKernelModules = ["nouveau"];

  # === GRAPHICS ===
  # NVIDIA RTX series
  services.xserver.videoDrivers = ["nvidia"];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    powerManagement.enable = true;
  };

  # === CPU ===
  # AMD Ryzen series
  hardware.cpu.amd.updateMicrocode = true;

  # === BLUETOOTH ===
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

  # === DISKS ===
  # 3x NVMe LUKS devices forming one Btrfs RAID1 pool.
  # All Btrfs subvolumes can be mounted through any opened mapper device.
  boot.initrd.luks.devices = {
    "nvme-1" = {
      device = "/dev/disk/by-uuid/72c1e4df-53ce-4346-887a-6de7fb4cb567";
      crypttabExtraOpts = ["password-cache=yes"];
    };

    "nvme-2" = {
      device = "/dev/disk/by-uuid/ee4b72d5-bde8-4b41-aea1-4f3295de0222";
      crypttabExtraOpts = ["password-cache=yes"];
    };

    "nvme-3" = {
      device = "/dev/disk/by-uuid/5504aab3-3024-4090-985e-5f7a5954b6aa";
      crypttabExtraOpts = ["password-cache=yes"];
    };
  };

  fileSystems."/" = {
    device = "/dev/mapper/nvme-1";
    fsType = "btrfs";
    options = ["compress=zstd" "noatime" "subvol=@root"];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/nvme-1";
    fsType = "btrfs";
    options = ["compress=zstd" "noatime" "subvol=@home"];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/nvme-1";
    fsType = "btrfs";
    options = ["compress=zstd" "noatime" "subvol=@nix"];
  };

  fileSystems."/.snapshots" = {
    device = "/dev/mapper/nvme-1";
    fsType = "btrfs";
    options = ["compress=zstd" "noatime" "subvol=@snapshots"];
  };

  fileSystems."/persist" = {
    device = "/dev/mapper/nvme-1";
    fsType = "btrfs";
    options = ["compress=zstd" "noatime" "subvol=@persist"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D4D6-EC57";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  fileSystems."/mnt/sata-a" = {
    device = "/dev/disk/by-label/sata-a";
    fsType = "ext4";
    options = ["nofail" "x-systemd.device-timeout=10s"];
  };

  fileSystems."/mnt/sata-b" = {
    device = "/dev/disk/by-label/sata-b";
    fsType = "ext4";
    options = ["nofail" "x-systemd.device-timeout=10s"];
  };

  fileSystems."/mnt/sata-c" = {
    device = "/dev/disk/by-label/sata-c";
    fsType = "ext4";
    options = ["nofail" "x-systemd.device-timeout=10s"];
  };

  swapDevices = [];
}
