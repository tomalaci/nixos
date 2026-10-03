# This module configures the system boot process, including the bootloader and kernel parameters.
# Also provides generally better boot experience
{lib, ...}: {
  # disko's VM test (nixos-anywhere --vm-test) formats LUKS with the dummy key
  # "secretsecret" and must type it at boot; without Plymouth the prompt is on
  # the serial console where the test can answer it.
  disko.tests = {
    extraConfig.boot.plymouth.enable = lib.mkForce false;
    bootCommands = ''
      machine.wait_for_console_text("Please enter passphrase")
      machine.send_console("secretsecret\n")
    '';
  };

  boot = {
    # Plymouth boot splash screen
    plymouth = {
      enable = true;
      theme = "spinner";
    };

    # Enable silent boot and reduce log verbosity
    consoleLogLevel = lib.mkDefault 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "rd.udev.log_level=3"
      "rd.systemd.show_status=auto"
    ];

    # OS loader settings
    loader = {
      timeout = 2;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
