# This module configures the system boot process, including the bootloader and kernel parameters.
# Also provides generally better boot experience
{...}: {
  boot = {
    # Plymouth boot splash screen
    plymouth = {
      enable = true;
      theme = "spinner";
    };

    # Enable silent boot and reduce log verbosity
    consoleLogLevel = 3;
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
