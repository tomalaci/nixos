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
  };
}
