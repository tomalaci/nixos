# Single-disk layout for laptops, applied by disko at install time (see
# README.md, "Installing a host"): a 1 GiB EFI system partition and one LUKS
# container with a Btrfs filesystem. The subvolumes match the desktop's
# (@root, @home, @nix, @snapshots, @persist), so Docker on Btrfs and the btrbk
# snapshots in modules/system/backup.nix work the same on every host.
#
# The LUKS passphrase is read from /tmp/secret.key only while formatting; at
# boot it is typed at the prompt. disko also generates fileSystems and
# boot.initrd.luks from this, so a host using it defines neither.
{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.local.disko;
  btrfsOptions = ["compress=zstd" "noatime"];
in {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.local.disko.device = lib.mkOption {
    type = lib.types.str;
    example = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNX0R000000X";
    description = "Whole disk to install to. Everything on it is erased.";
  };

  config.disko.devices.disk.main = {
    type = "disk";
    inherit (cfg) device;
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
