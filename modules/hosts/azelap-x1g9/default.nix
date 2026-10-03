# azelap-x1g9: ThinkPad X1 Carbon Gen 9 (Intel Tiger Lake, integrated graphics).
{inputs, ...}: {
  imports = [
    ./hardware.nix
    ../../disko/laptop.nix
    ../../system/laptop.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
  ];

  # Replace with the disk's /dev/disk/by-id/ path (ls -l /dev/disk/by-id on the
  # laptop) before installing: everything on it is erased.
  local.disko.device = "/dev/nvme0n1";

  # Backups: create a Storage Box sub-account first (README.md, "Backups"),
  # then enable with its user name and snapshots = true.
  # local.backup = {
  #   enable = true;
  #   boxUser = "u682168-subN";
  #   snapshots = true;
  # };
}
