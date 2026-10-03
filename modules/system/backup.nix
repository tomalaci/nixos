# Backups of the irreplaceable parts of /home/tomalaci (the disks are already
# RAID1; this covers deletion, corruption, and losing the machine).
#
# - btrbk: hourly read-only snapshots of @home in /.snapshots/home, for undoing
#   local mistakes. Nothing running as the user can change them.
# - restic: daily encrypted backup to the Hetzner Storage Box (BX11), over SFTP
#   on port 23 with a root-only key. Agents never see the key or the password.
#   The Storage Box's own snapshots (set in the Hetzner Console) protect the
#   repository against anything that gets hold of that key.
#
# One-time setup (as root, never committed):
#   /etc/restic/storagebox      SSH key, public half in the box's authorized_keys
#   /etc/restic/password        repository password (copy kept in Proton Pass)
# Restore: sudo restic-storagebox snapshots / restore <id> --target <dir>
{pkgs, ...}: let
  user = "tomalaci";
  box = "u682168@u682168.your-storagebox.de";
in {
  programs.ssh.knownHosts.storagebox = {
    hostNames = ["[u682168.your-storagebox.de]:23"];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
  };

  services.restic.backups.storagebox = {
    initialize = true;
    # Adds `restic-storagebox`, restic with this repository and password preset.
    createWrapper = true;
    repository = "sftp:${box}:restic";
    passwordFile = "/etc/restic/password";
    extraOptions = [
      "sftp.command='ssh ${box} -p 23 -i /etc/restic/storagebox -o IdentitiesOnly=yes -s sftp'"
    ];
    # Only what exists nowhere else: most data lives in cloud services and
    # Proton Pass, and repositories are on GitHub (this covers uncommitted work
    # and ignored files such as .env and local configs).
    paths = map (path: "/home/${user}/${path}") [
      "src"
      ".ssh"
      ".secrets"
      "Documents"
      "Pictures"
      ".local/share/foundry-vtt"
      ".local/state/ai-stats"
      ".claude/projects"
    ];
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
    serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
    };
  };

  services.btrbk.instances.home = {
    onCalendar = "hourly";
    settings = {
      snapshot_preserve_min = "6h";
      snapshot_preserve = "48h 14d 4w";
      subvolume."/home".snapshot_dir = "/.snapshots/home";
    };
  };
  systemd.tmpfiles.rules = ["d /.snapshots/home 0700 root root -"];

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
