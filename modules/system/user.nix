# This module configures the user accounts and related settings for the system.
{pkgs, ...}: {
  security.sudo.wheelNeedsPassword = true;
  users.users.tomalaci = {
    isNormalUser = true;
    description = "Tomass Lacis";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "docker"
    ];
    shell = pkgs.zsh;
    # Main SSH key (also curl-able onto the NixOS installer; README.md,
    # "Installing a host"). Password login is disabled in services.nix.
    openssh.authorizedKeys.keyFiles = [../../keys/tomalaci.pub];
  };
}
