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

  # System submodules
  imports = [
    ./boot.nix
    ./fonts.nix
    ./gaming.nix
    ./kde.nix
    ./locale.nix
    ./programs.nix
    ./services.nix
    ./user.nix
  ];
}
