# Scheduled AI and maintenance jobs as systemd user timers. They run in the
# background with no window; results go to ~/.local/state/ai-jobs/<job>/ with a
# single desktop notification. Both jobs are light and download nothing, so
# they catch up at login when missed.
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
