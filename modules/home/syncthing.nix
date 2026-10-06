# Syncthing keeps Claude Code's sessions and project memories
# (~/.claude/projects) in step between machines, directly over Tailscale: no
# discovery servers or relays. azelab (its own repository) lists the same
# devices and folder.
#
# Each machine's identity is the key pair in ~/.local/state/syncthing, made
# once with `syncthing generate --home ~/.local/state/syncthing`; its device
# ID goes in `devices` below and in the azelab repository. A machine whose ID
# is not listed is not trusted by the others. Session paths must match across
# machines (same home directory and ~/src layout), since Claude names each
# project folder after its path.
{config, ...}: let
  tailnet = "sargo-climb.ts.net";
  devices = {
    azelab = "LVVD2PG-TWOSOHD-4F56VPL-VM76X7A-FOWJD2J-NEMKPTF-XCEARQB-EDLJDA6";
    azelap-p16g5 = "DLJMHMM-GSULGMR-SGESQ7F-OK7IMUM-VQUTB62-ORJ2LJ7-CWSZQNN-HWYBHAR";
    # azepc-main, azelap-x1g9, azelap-ga502: add after `syncthing generate`
    # there, with their ~/.claude/projects emptied first.
  };
in {
  services.syncthing = {
    enable = true;
    # The devices and folders here are the whole configuration; changes made in
    # the web UI (http://127.0.0.1:8384) are reverted at the next start.
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      options = {
        globalAnnounceEnabled = false;
        localAnnounceEnabled = false;
        relaysEnabled = false;
        natEnabled = false;
        urAccepted = -1;
        # Reachable only on tailscale0 (modules/system/services.nix).
        listenAddresses = ["tcp://0.0.0.0:22000"];
      };
      devices =
        builtins.mapAttrs (name: id: {
          inherit id;
          addresses = ["tcp://${name}.${tailnet}:22000"];
        })
        devices;
      folders.claude-projects = {
        label = "Claude Code projects";
        path = "${config.home.homeDirectory}/.claude/projects";
        devices = builtins.attrNames devices;
        # Replaced and deleted files are kept for 30 days, outside the folder so
        # Claude does not list them as projects.
        versioning = {
          type = "staggered";
          fsPath = "${config.xdg.stateHome}/syncthing/versions/claude-projects";
          params = {
            cleanInterval = "3600";
            maxAge = "2592000";
          };
        };
        # A conflict copy stays on the machine where it appeared instead of
        # showing up in every machine's /resume list.
        ignorePatterns = ["*.sync-conflict-*"];
      };
    };
  };
}
