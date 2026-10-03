# Generated per machine; do not write it by hand. The install replaces this
# file with the output of
#   nixos-generate-config --no-filesystems --show-hardware-config
# run on the target (nixos-anywhere does it with --generate-hardware-config;
# README.md, "Installing a host"). Commit the result. It holds the initrd and
# kernel modules and the platform; filesystems come from disko.nix.
#
# Until then, typical values let the host evaluate: Intel uses kvm-intel and
# usually "thunderbolt"; AMD uses kvm-amd.
{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "usb_storage" "sd_mod"];
  boot.kernelModules = ["kvm-intel"];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
