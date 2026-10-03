# Disk layout, applied by disko when the host is installed (README.md,
# "Installing a host"). disko also generates fileSystems and boot.initrd.luks
# from this, so default.nix and hardware.nix define neither. Changing it later
# only takes effect on reinstall.
#
# This is the single-disk layout every laptop uses: a 1 GiB EFI partition and
# one LUKS container with a Btrfs filesystem. Keep the subvolume names: Docker
# on Btrfs and the btrbk snapshots in modules/system/backup.nix (/home and
# /.snapshots) rely on them. For more disks, add entries under disko.devices.disk
# (examples: https://github.com/nix-community/disko/tree/master/example).
_: let
  btrfsOptions = ["compress=zstd" "noatime"];
in {
  # FILL IN: the whole disk to install to, by its stable path. On the target,
  # booted from the installer: ls -l /dev/disk/by-id (pick the nvme-... entry
  # without -partN). Everything on it is erased.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-EXAMPLE_SSD_1TB_S0000000000000";
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
