# Template for a new host; it is never installed. The flake builds it like the
# others, so it keeps evaluating as shared modules change.
#
# To add a host:
#   1. Copy this directory to modules/hosts/<hostname>/; the directory name
#      becomes networking.hostName and the nixosConfigurations output name.
#      Laptops are named azelap-<model>, desktops azepc-<role>.
#   2. Add <hostname> to `hosts` in flake.nix.
#   3. Fill in the FILL IN parts below and in disko.nix, and delete the hints
#      that do not apply.
#   4. Install it (README.md, "Installing a host"), which replaces hardware.nix,
#      and put NIX_HOST=<hostname> in ~/.nix-host on the machine.
#
# Every host already gets modules/system/system.nix (Plasma, programs,
# services, user, locale, fonts, boot) and the Home Manager profile from
# mkHost in flake.nix; only what differs belongs here.
# FILL IN: one line naming the machine, e.g. "ThinkPad X1 Carbon Gen 9 (Intel
# Tiger Lake, integrated graphics)."
{inputs, ...}: {
  imports = [
    ./hardware.nix
    ./disko.nix

    # FILL IN: optional system modules. Keep the ones this machine needs:
    ../../system/laptop.nix # zram swap, fwupd, backups only on AC power
    # ../../system/gaming.nix       # Steam, Proton, Wine, Lutris, Gamescope
    # ../../system/peripherals.nix  # OpenRGB, SteelSeries, Arctis, input-remapper
    # ../../system/usenet.nix       # NZBGet, NZBHydra2

    # FILL IN: the machine's nixos-hardware profile, which sets CPU, GPU, power,
    # and quirks. List them with:
    #   nix eval --json github:NixOS/nixos-hardware#nixosModules --apply builtins.attrNames
    # Without an exact model, combine the generic ones (see azelap-p16g5):
    # lenovo-thinkpad, common-cpu-intel / common-cpu-amd, common-pc-ssd, and
    # "${inputs.nixos-hardware}/common/gpu/nvidia/<generation>" plus
    # ".../common/gpu/nvidia/prime.nix" for hybrid graphics.
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # NVIDIA hybrid graphics (laptops with a discrete GPU): integrated graphics by
  # default, `nvidia-offload <command>` for the NVIDIA GPU. Bus IDs from
  # `lspci -D | grep -E 'VGA|3D'` (0000:01:00.0 is PCI:1:0:0); a model profile
  # may already set them.
  # hardware.nvidia = {
  #   prime = {
  #     intelBusId = "PCI:0:2:0"; # or amdgpuBusId on AMD
  #     nvidiaBusId = "PCI:1:0:0";
  #   };
  #   powerManagement = {
  #     enable = true;
  #     finegrained = true; # power the GPU down when idle
  #   };
  # };
  #
  # A desktop NVIDIA GPU instead sets the driver itself, as azepc-main does:
  # services.xserver.videoDrivers = ["nvidia"]; plus hardware.nvidia options.

  # Backups: create a Storage Box sub-account first (README.md, "Backups"),
  # then enable with its user name. snapshots needs the @home and @snapshots
  # subvolumes from disko.nix.
  # local.backup = {
  #   enable = true;
  #   boxUser = "u682168-subN";
  #   snapshots = true;
  # };
}
