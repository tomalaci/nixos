# Backups of the irreplaceable parts of the home directory, per host. A host
# opts in from modules/hosts/<host>.nix, for example:
#
#   local.backup = {
#     enable = true;
#     boxUser = "u682168-sub1";   # this host's Storage Box sub-account
#     snapshots = true;            # btrbk; needs /home and /.snapshots subvolumes
#     onlyOnAC = true;             # laptops
#   };
#
# - restic: daily encrypted backup to the Hetzner Storage Box, one repository
#   per host, each under its own sub-account (locked to its own directory, with
#   its own key and password). A lost or compromised device can reach only its
#   own backups; the main account stays off every machine. The box's own
#   snapshots (Hetzner Console) protect against anything holding a host's key.
# - btrbk: hourly read-only snapshots of /home in /.snapshots/home, for undoing
#   local mistakes. Nothing running as the user can change them.
#
# One-time setup per host (as root, never committed):
#   /etc/restic/storagebox   SSH key; public half in the sub-account's
#                            .ssh/authorized_keys (ssh-copy-id -p 23 -s)
#   /etc/restic/password     repository password (copy kept in Proton Pass)
# Restore: sudo restic-storagebox snapshots / restore <id> --target <dir>
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.backup;
  user = "tomalaci";
  host = "${cfg.boxUser}.your-storagebox.de";
  login = "${cfg.boxUser}@${host}";
in {
  options.local.backup = {
    enable = lib.mkEnableOption "restic backups to the Hetzner Storage Box";
    boxUser = lib.mkOption {
      type = lib.types.str;
      description = "This host's Storage Box sub-account, for example u682168-sub1.";
    };
    hostKey = lib.mkOption {
      type = lib.types.str;
      # The same key for every account of the box.
      default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
      description = "SSH host key of the Storage Box on port 23.";
    };
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # Only what exists nowhere else: most data lives in cloud services and
      # Proton Pass, and repositories are on GitHub (this covers uncommitted
      # work and ignored files such as .env and local configs).
      default = [
        "src"
        ".ssh"
        ".secrets"
        "Documents"
        "Pictures"
        ".local/state/ai-stats"
        ".claude/projects"
      ];
      description = "Paths to back up, relative to the home directory.";
    };
    extraPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Host-specific paths, relative to the home directory.";
    };
    snapshots = lib.mkEnableOption "hourly btrbk snapshots of /home in /.snapshots/home";
    onlyOnAC = lib.mkEnableOption "skipping backups while on battery";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.ssh.knownHosts.storagebox = {
        hostNames = ["[${host}]:23"];
        publicKey = cfg.hostKey;
      };

      services.restic.backups.storagebox = {
        initialize = true;
        # Adds `restic-storagebox`, restic with this repository and password preset.
        createWrapper = true;
        repository = "sftp:${login}:restic";
        passwordFile = "/etc/restic/password";
        extraOptions = [
          "sftp.command='ssh ${login} -p 23 -i /etc/restic/storagebox -o IdentitiesOnly=yes -s sftp'"
        ];
        paths = map (path: "/home/${user}/${path}") (cfg.paths ++ cfg.extraPaths);
        exclude = [
          # Per-project dependencies and build output.
          "node_modules"
          ".venv"
          "__pycache__"
        ];
        # Also skips directories marked with CACHEDIR.TAG (cargo target/, many caches).
        extraBackupArgs = ["--exclude-caches" "--one-file-system"];
        pruneOpts = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 6"];
        # Verify a small random part of the stored data after each run.
        runCheck = true;
        checkOpts = ["--read-data-subset=2%"];
        timerConfig = {
          OnCalendar = "*-*-* 12:30:00";
          # A missed run catches up after boot, spread out so it does not slow login.
          Persistent = true;
          RandomizedDelaySec = "30m";
        };
      };

      systemd.services.restic-backups-storagebox = {
        onFailure = ["backup-failed-notify.service"];
        unitConfig.ConditionACPower = lib.mkIf cfg.onlyOnAC true;
        serviceConfig = {
          Nice = 19;
          IOSchedulingClass = "idle";
          CPUSchedulingPolicy = "idle";
        };
      };

      # Desktop notification for the user when a backup fails.
      systemd.services.backup-failed-notify = {
        description = "Notify the desktop user that a backup failed";
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.util-linux}/bin/runuser -u ${user} -- env \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u ${user})/bus \
            ${pkgs.libnotify}/bin/notify-send --urgency=critical --app-name=backup \
            "Backup failed" "journalctl -u restic-backups-storagebox"
        '';
      };
    }

    (lib.mkIf cfg.snapshots {
      services.btrbk.instances.home = {
        onCalendar = "hourly";
        settings = {
          snapshot_preserve_min = "6h";
          snapshot_preserve = "48h 14d 4w";
          subvolume."/home".snapshot_dir = "/.snapshots/home";
        };
      };
      systemd.tmpfiles.rules = ["d /.snapshots/home 0700 root root -"];
    })
  ]);
}
