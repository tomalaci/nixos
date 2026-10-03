# Shared laptop settings. Model-specific tuning (TLP or power profiles,
# trackpoint, PRIME bus IDs) comes from nixos-hardware in each host file.
{...}: {
  # Laptops have no swap partition (see modules/disko/laptop.nix).
  zramSwap.enable = true;

  # Firmware and UEFI updates from LVFS: `fwupdmgr refresh && fwupdmgr update`.
  services.fwupd.enable = true;

  # Do not start the daily backup on battery.
  local.backup.onlyOnAC = true;
}
