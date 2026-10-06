# SSH client config (~/.ssh/config). azelab is the remote dev server, managed
# from its own repository (~/src/tomalaci/azelab); its SSH port is not 22.
_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      # Over the tailnet (MagicDNS name).
      azelab = {
        HostName = "azelab";
        Port = 29904;
        User = "tomalaci";
      };
      # Public address; the Hetzner firewall admits only the owner's ranges.
      azelab-public = {
        HostName = "65.108.134.242";
        Port = 29904;
        User = "tomalaci";
      };
    };
  };
}
