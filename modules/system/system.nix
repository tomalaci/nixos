{...}: {
  # NixOS configuration options
  system.stateVersion = "26.05";
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
    auto-optimise-store = true;
  };
  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  # System submodules shared by every host. Hosts import the optional ones
  # (gaming, laptop, peripherals, usenet) from modules/hosts/<host>/.
  imports = [
    ./backup.nix
    ./boot.nix
    ./fonts.nix
    ./kde.nix
    ./locale.nix
    ./programs.nix
    ./services.nix
    ./user.nix
  ];
}
