# azelap-p16g5: ThinkPad P16s Gen 5 Intel (Core Ultra, Arrow Lake) with an NVIDIA
# RTX PRO 500 Blackwell; company laptop. nixos-hardware has no profile for this
# generation yet, so it combines the generic ThinkPad, Intel, and NVIDIA ones.
{inputs, ...}: {
  imports = [
    ./hardware.nix
    ../../disko/laptop.nix
    ../../system/laptop.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    # Blackwell needs the open kernel module; this module selects it.
    "${inputs.nixos-hardware}/common/gpu/nvidia/blackwell"
    "${inputs.nixos-hardware}/common/gpu/nvidia/prime.nix"
  ];

  # Replace with the disk's /dev/disk/by-id/ path (ls -l /dev/disk/by-id on the
  # laptop) before installing: everything on it is erased.
  local.disko.device = "/dev/nvme0n1";

  # PRIME offload: Intel graphics by default, `nvidia-offload <command>` for the
  # NVIDIA GPU, which powers down when idle. Check both IDs with
  # `lspci -D | grep -E 'VGA|3D'` (0000:01:00.0 is PCI:1:0:0).
  hardware.nvidia = {
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
  };

  # Backups: create a Storage Box sub-account first (README.md, "Backups"),
  # then enable with its user name and snapshots = true.
  # local.backup = {
  #   enable = true;
  #   boxUser = "u682168-subN";
  #   snapshots = true;
  # };
}
