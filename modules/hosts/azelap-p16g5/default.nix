# azelap-p16g5: ThinkPad P16s Gen 5 Intel (21XE, Core Ultra 7 356H, Panther
# Lake) with an NVIDIA RTX PRO 500 Blackwell and Intel Wi-Fi 7 (8086:e340);
# company laptop, also used for gaming. nixos-hardware has no profile for this
# generation yet, so it combines the generic ThinkPad, Intel, and NVIDIA ones.
{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ../../system/laptop.nix
    ../../system/gaming.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    # Blackwell needs the open kernel module; this module selects it.
    "${inputs.nixos-hardware}/common/gpu/nvidia/blackwell"
    "${inputs.nixos-hardware}/common/gpu/nvidia/prime.nix"
  ];

  # Panther Lake graphics need the xe driver (i915 does not support it; the
  # nixos-hardware default) and a recent kernel, as does the Wi-Fi 7 card.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.intelgpu = {
    driver = "xe";
    vaapiDriver = "intel-media-driver";
  };

  # PRIME offload: Intel graphics by default, `nvidia-offload <command>` for the
  # NVIDIA GPU, which powers down when idle. Check both IDs with
  # `lspci -D | grep -E 'VGA|3D'` (0000:01:00.0 is PCI:1:0:0); checked on the
  # machine.
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
  #   onlyOnAC = true; # skip runs on battery; a missed run catches up later
  # };
}
