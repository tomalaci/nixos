{...}: {
  # NixOS configuration options
  system.stateVersion = "26.05";
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
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
