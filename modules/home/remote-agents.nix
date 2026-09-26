# Remote access to agents from a phone or browser (claude.ai/code, Claude app).
#
# claude-remote runs Claude Code's Remote Control server in ~/src, so new
# sessions can be started from afar and run here with local repos and tools.
# It runs inside a private tmux server (server mode draws a terminal UI); see it
# with `tmux -L claude-remote attach`, detach with C-b d. The server exits after
# about 10 minutes without network, so systemd restarts it.
#
# claude-presence keeps $XDG_RUNTIME_DIR/claude-present in step with the screen
# lock; Claude Code skips mobile push notifications while that file exists.
{
  config,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  tmux = "${pkgs.tmux}/bin/tmux -L claude-remote";
in {
  home.sessionVariables.CLAUDE_CLIENT_PRESENCE_FILE = "\${XDG_RUNTIME_DIR}/claude-present";

  systemd.user.services = {
    claude-remote = {
      Unit.Description = "Claude Code Remote Control server in ~/src";
      Service = {
        Type = "forking";
        Environment = ["CLAUDE_CLIENT_PRESENCE_FILE=%t/claude-present"];
        # A login shell, so sessions get the same PATH and variables as a terminal.
        ExecStart = "${tmux} new-session -d -s remote -x 160 -y 48 -c ${home}/src ${pkgs.zsh}/bin/zsh -lc 'exec claude remote-control --spawn same-dir --no-create-session-in-dir'";
        ExecStop = "${tmux} kill-server";
        Restart = "always";
        RestartSec = "30s";
      };
      # Starts at login in the background: no downloads, only a connection.
      Install.WantedBy = ["default.target"];
    };

    claude-presence = {
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
  };
}
