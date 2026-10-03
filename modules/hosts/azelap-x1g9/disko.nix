# Disk layout, applied by disko at install time (README.md, "Installing a
# host"): a 1 GiB EFI partition and one LUKS container with Btrfs subvolumes
# matching the other hosts. disko also generates fileSystems and
# boot.initrd.luks from this. Changing it only takes effect on reinstall.
_: let
  btrfsOptions = ["compress=zstd" "noatime"];
in {
  # Replace with the disk's /dev/disk/by-id/ path (ls -l /dev/disk/by-id on the
  # laptop) before installing: everything on it is erased.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-SKHynix_HFS512GEJ9X102N_SJB7N772913807U5L";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["fmask=0077" "dmask=0077"];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            # Read only while formatting; the passphrase is typed at every boot.
            passwordFile = "/tmp/secret.key";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = ["-f"];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = btrfsOptions;
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = btrfsOptions;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsOptions;
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = btrfsOptions;
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = btrfsOptions;
                };
              };
            };
          };
        };
      };
    };
  };
}
