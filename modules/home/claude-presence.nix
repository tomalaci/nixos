# Presence marker for Claude Code's mobile push notifications, used with Remote
# Control (`claude remote-control`, started by hand when needed).
#
# claude-presence runs ai-presence, which keeps $XDG_RUNTIME_DIR/claude-present
# in step with the screen lock; Claude Code skips push notifications while that
# file exists (CLAUDE_CLIENT_PRESENCE_FILE), so they arrive only while the
# screen is locked.
{config, ...}: let
  home = config.home.homeDirectory;
in {
  home.sessionVariables.CLAUDE_CLIENT_PRESENCE_FILE = "\${XDG_RUNTIME_DIR}/claude-present";

  systemd.user.services.claude-presence = {
    Unit = {
      Description = "Claude Code presence marker from the screen lock";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${home}/src/ai-config/bin/ai-presence --file %t/claude-present";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
