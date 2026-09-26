# Scheduled AI and maintenance jobs as systemd user timers. They run in the
# background with no window; results go to ~/.local/state/ai-jobs/<job>/ with a
# single desktop notification. Nothing here runs during boot or login except
# the weekly ai-stats report, which is local-only and catches up when missed.
{config, ...}: let
  home = config.home.homeDirectory;
  # Keep background jobs from competing with interactive work.
  lowPriority = {
    Nice = 19;
    IOSchedulingClass = "idle";
    CPUSchedulingPolicy = "idle";
  };
in {
  systemd.user = {
    services = {
      flake-update-check = {
        Unit.Description = "Daily flake update check: build, diff, and AI summary (no switch)";
        Service =
          lowPriority
          // {
            Type = "oneshot";
            ExecStart = "${home}/src/nixos/scripts/flake-update-check.py";
            # Builds may compile uncached packages (capped at 6 cores by the script).
            TimeoutStartSec = "5h";
          };
      };
      ai-stats-report = {
        Unit.Description = "Weekly agent statistics report";
        Service =
          lowPriority
          // {
            Type = "oneshot";
            ExecStart = "${home}/src/ai-config/bin/ai-stats report";
            TimeoutStartSec = "5m";
          };
      };
    };

    timers = {
      flake-update-check = {
        Unit.Description = "Daily flake update check at 11:00";
        # Missed runs are skipped, never replayed at login: the next one is tomorrow.
        Timer = {
          OnCalendar = "*-*-* 11:00:00";
          Persistent = false;
        };
        Install.WantedBy = ["timers.target"];
      };
      ai-stats-report = {
        Unit.Description = "Weekly agent statistics report on Sundays at 11:00";
        # Missed runs catch up at the next login; the report is cheap and local.
        Timer = {
          OnCalendar = "Sun *-*-* 11:00:00";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
