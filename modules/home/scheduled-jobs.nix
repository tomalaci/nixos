# Scheduled AI and maintenance jobs as systemd user timers. They run in the
# background with no window; results go to ~/.local/state/ai-jobs/<job>/ with a
# single desktop notification. Nothing here runs during boot or login except
# the weekly ai-health check and ai-stats report, which catch up when missed:
# both are light and download nothing.
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
      ai-health = {
        Unit.Description = "Weekly agent health check (notifies only on failure)";
        Service =
          lowPriority
          // {
            Type = "oneshot";
            ExecStart = "${home}/src/ai-config/bin/ai-health --notify";
            TimeoutStartSec = "20m";
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
      ai-health = {
        Unit.Description = "Weekly agent health check on Sundays at 10:50";
        # Missed runs catch up at the next login: a few small API calls, no downloads.
        Timer = {
          OnCalendar = "Sun *-*-* 10:50:00";
          Persistent = true;
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
