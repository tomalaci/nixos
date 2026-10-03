# Placeholder with typical values for this model, until the first install
# replaces it with the output of
# `nixos-generate-config --no-filesystems --show-hardware-config` (nixos-anywhere
# does this with --generate-hardware-config; see README.md). Filesystems and
# LUKS come from disko.nix, not from here.
{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "sd_mod"];
  boot.kernelModules = ["kvm-intel"];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
