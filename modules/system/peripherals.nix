# Desk peripherals: RGB lighting, SteelSeries mouse and Arctis headset, and
# input remapping. Imported by hosts that have them attached.
{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.arctis-sound-manager.nixosModules.default
  ];

  services.hardware.openrgb.enable = true;
  services.udev.packages = [pkgs.rivalcfg];
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="1038", MODE="0666"
  ''; # Extra rules for steelseries devices
  services.arctis-sound-manager.enable = true;
  services.input-remapper = {
    enable = true;
    enableUdevRules = true;
  };

  environment.systemPackages = with pkgs; [
    openrgb
    rivalcfg
  ];
}
