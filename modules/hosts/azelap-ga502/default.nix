# azelap-ga502: ASUS ROG Zephyrus G15 GA502IV (Ryzen 4000, NVIDIA RTX 2060).
{
  inputs,
  lib,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ../../system/laptop.nix
    ../../system/gaming.nix
    # PRIME offload with the bus IDs of this model: AMD graphics by default,
    # `nvidia-offload <command>` (or Steam's launch options) for the NVIDIA GPU.
    inputs.nixos-hardware.nixosModules.asus-zephyrus-ga502
  ];

  hardware.nvidia = {
    # The profile assumes the Radeon iGPU at PCI:6:0:0; on this unit it is at
    # 0000:05:00.0 (checked with lspci). The NVIDIA GPU is at PCI:1:0:0.
    prime.amdgpuBusId = lib.mkForce "PCI:5:0:0";
    # Let the NVIDIA GPU power down when idle.
    powerManagement = {
      enable = true;
      finegrained = true;
    };
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
