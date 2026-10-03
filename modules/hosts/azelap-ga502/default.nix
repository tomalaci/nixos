# azelap-ga502: ASUS ROG Zephyrus G15 GA502IV (Ryzen 4000, NVIDIA RTX 2060).
{inputs, ...}: {
  imports = [
    ./hardware.nix
    ../../disko/laptop.nix
    ../../system/laptop.nix
    ../../system/gaming.nix
    # PRIME offload with the bus IDs of this model: AMD graphics by default,
    # `nvidia-offload <command>` (or Steam's launch options) for the NVIDIA GPU.
    inputs.nixos-hardware.nixosModules.asus-zephyrus-ga502
  ];

  # Replace with the disk's /dev/disk/by-id/ path (ls -l /dev/disk/by-id on the
  # laptop) before installing: everything on it is erased.
  local.disko.device = "/dev/nvme0n1";

  # Let the NVIDIA GPU power down when idle.
  hardware.nvidia.powerManagement = {
    enable = true;
    finegrained = true;
  };

  # asusd (asusctl): fan profiles, keyboard backlight, and battery charge limit.
  services.asusd.enable = true;

  # Backups: create a Storage Box sub-account first (README.md, "Backups"),
  # then enable with its user name and snapshots = true.
  # local.backup = {
  #   enable = true;
  #   boxUser = "u682168-subN";
  #   snapshots = true;
  # };
}
